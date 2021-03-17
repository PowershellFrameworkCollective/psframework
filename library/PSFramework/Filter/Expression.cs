using PSFramework.Utility;
using System;
using System.Collections.Generic;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Linq;
using System.Text.RegularExpressions;

namespace PSFramework.Filter
{
    /// <summary>
    /// Stores a filter expression and executes it as needed.
    /// </summary>
    public class Expression : ICloneable
    {
        /// <summary>
        /// The filter expression string
        /// </summary>
        public string ExpressionString
        {
            get { return _ExpressionString; }
            set
            {
                _EffectiveExpression = Parse(value);
                _ExpressionString = value;
            }
        }
        private string _ExpressionString;
        private string _EffectiveExpression;

        /// <summary>
        /// The ConditionSet under which this expression will be executed.
        /// </summary>
        public ConditionSet ConditionSet;

        /// <summary>
        /// Name of the conditions that make up this expression
        /// </summary>
        public string[] Conditions
        {
            get { return _Conditions.ToArray(); }
        }
        private List<string> _Conditions = new List<string>();

        /// <summary>
        /// Create a new expression object based off a filter expression.
        /// </summary>
        /// <param name="Expression">The filter expression that will be evaluated</param>
        /// <param name="ConditionSet">The condition set under which the expression will be evaluated. Every condition used in the expression must be part of this set.</param>
        public Expression(string Expression, ConditionSet ConditionSet  = null)
        {
            ExpressionString = Expression;
            this.ConditionSet = ConditionSet;
        }

        /// <summary>
        /// Evaluates the filter expression.
        /// </summary>
        /// <param name="Argument">Optional argument, in case the conditions are designed to evaluate a specific object</param>
        /// <param name="ConditionSet">Optional argument, in case the ConditionSet was not specified at creation time.</param>
        /// <returns>Whether the expression is true or not</returns>
        public bool Evaluate(object Argument = null, ConditionSet ConditionSet = null)
        {
            if (ConditionSet == null && this.ConditionSet == null)
                throw new PsfException("PSFramework.Assembly.Filter.ConditionSet.Required");
            if (_Conditions.Count < 1)
                throw new PsfException("PSFramework.Assembly.Filter.NoCondition");

            ConditionSet currentSet = ConditionSet == null ? this.ConditionSet : ConditionSet;
            foreach (string conditionName in _Conditions)
                if (!currentSet.ConditionTable.ContainsKey(conditionName))
                    throw new PsfException("PSFramework.Assembly.Filter.Condition.NotInSet", null, conditionName, currentSet.Name, String.Join(",", currentSet.ConditionTable.Keys));

            Dictionary<string, bool> results = new Dictionary<string, bool>();
            Dictionary<bool, string> rMapping = new Dictionary<bool, string>()
            {
                { true, "(1)" },
                { false, "(0)" }
            };
            string tempExpression = _EffectiveExpression;
            foreach (Condition condition in _Conditions.Select(o => currentSet.ConditionTable[o]))
                tempExpression = Regex.Replace(tempExpression, $"\\({ condition.Name}\\)", rMapping[condition.Invoke(Argument)], RegexOptions.IgnoreCase);

            return LanguagePrimitives.IsTrue(ScriptBlock.Create(tempExpression).Invoke());
        }

        private string Parse(string Expression)
        {
            try
            {
                string convertedExpression = Regex.Replace(Regex.Replace(Expression, "([^\\d\\w_-])([\\d\\w_]+)", "$1($2)"), "^([\\d\\w_]+)", "($1)");
                Token[] tokens;
                ParseError[] errors;
                Parser.ParseInput(convertedExpression, out tokens, out errors);

                if (errors != null && errors.Length > 0)
                    throw new ArgumentException($"Ensure the syntax is correct: { Expression }");

                // Evaluate legal expression tokens. Can only contain logical operators, parenthesis and condition names
                Regex conditionName = new Regex("^[\\d\\w_]+$");
                foreach (Token token in tokens)
                {
                    if (token.Kind == TokenKind.And || token.Kind == TokenKind.Or || token.Kind == TokenKind.Not || token.Kind == TokenKind.Xor)
                        continue;
                    if (token.Kind == TokenKind.LParen || token.Kind == TokenKind.RParen)
                        continue;
                    if (token.Kind == TokenKind.Identifier && token.TokenFlags == TokenFlags.CommandName && conditionName.IsMatch(token.Text))
                        continue;
                    if (token.Kind == TokenKind.EndOfInput)
                        continue;
                    throw new ArgumentException($"Invalid token detected in expression: { Expression }");
                }
                _Conditions = tokens.Where(o => o.TokenFlags == TokenFlags.CommandName).Select(o => o.Text).Distinct().OrderBy(o => o).ToList();
                return convertedExpression;
            }
            catch (Exception e) { throw new PsfException("PSFramework.Assembly.Filter.Expression.SyntaxError", e, Expression); }
        }

        /// <summary>
        /// Clones the existing expression
        /// </summary>
        /// <returns>A clone of the current expression object</returns>
        public object Clone()
        {
            return new Expression(_ExpressionString, ConditionSet);
        }
    }
}
