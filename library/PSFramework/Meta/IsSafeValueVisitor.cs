using System.Collections;
using System.IO;
using System.Linq;
using System.Management.Automation.Language;

namespace PSFramework.Meta
{
    internal class IsSafeValueVisitor : ICustomAstVisitor
    {
        public static bool IsAstSafe(Ast ast, GetSafeValueVisitor.SafeValueContext safeValueContext)
        {
            IsSafeValueVisitor visitor = new IsSafeValueVisitor(safeValueContext);
            return visitor.IsAstSafe(ast);
        }

        internal IsSafeValueVisitor(GetSafeValueVisitor.SafeValueContext safeValueContext)
        {
            _safeValueContext = safeValueContext;
        }

        internal bool IsAstSafe(Ast ast)
        {
            if ((bool)ast.Accept(this) && _visitCount < MaxVisitCount)
            {
                return true;
            }

            return false;
        }

        // A readonly singleton with the default SafeValueContext.
        internal static readonly IsSafeValueVisitor Default = new IsSafeValueVisitor(GetSafeValueVisitor.SafeValueContext.Default);

        // This is a check of the number of visits
        private uint _visitCount = 0;
        private const uint MaxVisitCount = 5000;
        private const int MaxHashtableKeyCount = 500;

        // Used to determine if we are being called within a GetPowerShell() context,
        // which does some additional security verification outside of the scope of
        // what we can verify.
        private readonly GetSafeValueVisitor.SafeValueContext _safeValueContext;

        public object VisitErrorStatement(ErrorStatementAst errorStatementAst) { return false; }

        public object VisitErrorExpression(ErrorExpressionAst errorExpressionAst) { return false; }

        public object VisitScriptBlock(ScriptBlockAst scriptBlockAst) { return false; }

        public object VisitParamBlock(ParamBlockAst paramBlockAst) { return false; }

        public object VisitNamedBlock(NamedBlockAst namedBlockAst) { return false; }

        public object VisitTypeConstraint(TypeConstraintAst typeConstraintAst) { return false; }

        public object VisitAttribute(AttributeAst attributeAst) { return false; }

        public object VisitNamedAttributeArgument(NamedAttributeArgumentAst namedAttributeArgumentAst) { return false; }

        public object VisitParameter(ParameterAst parameterAst) { return false; }

        public object VisitFunctionDefinition(FunctionDefinitionAst functionDefinitionAst) { return false; }

        public object VisitIfStatement(IfStatementAst ifStmtAst) { return false; }

        public object VisitTrap(TrapStatementAst trapStatementAst) { return false; }

        public object VisitSwitchStatement(SwitchStatementAst switchStatementAst) { return false; }

        public object VisitDataStatement(DataStatementAst dataStatementAst) { return false; }

        public object VisitForEachStatement(ForEachStatementAst forEachStatementAst) { return false; }

        public object VisitDoWhileStatement(DoWhileStatementAst doWhileStatementAst) { return false; }

        public object VisitForStatement(ForStatementAst forStatementAst) { return false; }

        public object VisitWhileStatement(WhileStatementAst whileStatementAst) { return false; }

        public object VisitCatchClause(CatchClauseAst catchClauseAst) { return false; }

        public object VisitTryStatement(TryStatementAst tryStatementAst) { return false; }

        public object VisitBreakStatement(BreakStatementAst breakStatementAst) { return false; }

        public object VisitContinueStatement(ContinueStatementAst continueStatementAst) { return false; }

        public object VisitReturnStatement(ReturnStatementAst returnStatementAst) { return false; }

        public object VisitExitStatement(ExitStatementAst exitStatementAst) { return false; }

        public object VisitThrowStatement(ThrowStatementAst throwStatementAst) { return false; }

        public object VisitDoUntilStatement(DoUntilStatementAst doUntilStatementAst) { return false; }

        public object VisitAssignmentStatement(AssignmentStatementAst assignmentStatementAst) { return false; }

        public object VisitCommand(CommandAst commandAst) { return false; }

        public object VisitCommandExpression(CommandExpressionAst commandExpressionAst) { return false; }

        public object VisitCommandParameter(CommandParameterAst commandParameterAst) { return false; }

        public object VisitFileRedirection(FileRedirectionAst fileRedirectionAst) { return false; }

        public object VisitMergingRedirection(MergingRedirectionAst mergingRedirectionAst) { return false; }

        public object VisitAttributedExpression(AttributedExpressionAst attributedExpressionAst) { return false; }

        public object VisitBlockStatement(BlockStatementAst blockStatementAst) { return false; }

        public object VisitInvokeMemberExpression(InvokeMemberExpressionAst invokeMemberExpressionAst) { return false; }

        public object VisitIndexExpression(IndexExpressionAst indexExpressionAst)
        {
            return (bool)indexExpressionAst.Index.Accept(this) && (bool)indexExpressionAst.Target.Accept(this);
        }

        public object VisitExpandableStringExpression(ExpandableStringExpressionAst expandableStringExpressionAst)
        {
            bool isSafe = true;
            foreach (var nestedExpression in expandableStringExpressionAst.NestedExpressions)
            {
                _visitCount++;
                if (!(bool)nestedExpression.Accept(this))
                {
                    isSafe = false;
                    break;
                }
            }

            return isSafe;
        }

        public object VisitStatementBlock(StatementBlockAst statementBlockAst)
        {
            bool isSafe = true;
            foreach (var statement in statementBlockAst.Statements)
            {
                _visitCount++;
                if (statement == null)
                {
                    isSafe = false;
                    break;
                }

                if (!(bool)statement.Accept(this))
                {
                    isSafe = false;
                    break;
                }
            }

            return isSafe;
        }

        public object VisitPipeline(PipelineAst pipelineAst)
        {
            var expr = pipelineAst.GetPureExpression();
            return expr != null && (bool)expr.Accept(this);
        }

        public object VisitBinaryExpression(BinaryExpressionAst binaryExpressionAst)
        {
            // This can be used for a denial of service
            // Write-Output (((((("AAAAAAAAAAAAAAAAAAAAAA"*2)*2)*2)*2)*2)*2)
            // Keep on going with that pattern, and we're generating gigabytes of strings.
            return false;
        }

        public object VisitUnaryExpression(UnaryExpressionAst unaryExpressionAst)
        {
            bool unaryExpressionIsSafe = unaryExpressionAst.TokenKind.HasTrait(TokenFlags.CanConstantFold) &&
                !unaryExpressionAst.TokenKind.HasTrait(TokenFlags.DisallowedInRestrictedMode) &&
                (bool)unaryExpressionAst.Child.Accept(this);
            if (unaryExpressionIsSafe)
            {
                _visitCount++;
            }

            return unaryExpressionIsSafe;
        }

        public object VisitConvertExpression(ConvertExpressionAst convertExpressionAst)
        {
            var type = convertExpressionAst.Type.TypeName.GetReflectionType();
            if (type == null)
            {
                return false;
            }

            if (!type.IsSafePrimitive())
            {
                // Only do conversions to built-in types - other conversions might not
                // be safe to optimize.
                return false;
            }

            _visitCount++;
            return (bool)convertExpressionAst.Child.Accept(this);
        }

        public object VisitConstantExpression(ConstantExpressionAst constantExpressionAst)
        {
            _visitCount++;
            return true;
        }

        public object VisitStringConstantExpression(StringConstantExpressionAst stringConstantExpressionAst)
        {
            _visitCount++;
            return true;
        }

        public object VisitSubExpression(SubExpressionAst subExpressionAst)
        {
            return subExpressionAst.SubExpression.Accept(this);
        }

        public object VisitUsingExpression(UsingExpressionAst usingExpressionAst)
        {
            // $using:true should be safe - it's silly to write that, but not harmful.
            _visitCount++;
            return usingExpressionAst.SubExpression.Accept(this);
        }

        public object VisitVariableExpression(VariableExpressionAst variableExpressionAst)
        {
            _visitCount++;

            if (_safeValueContext == GetSafeValueVisitor.SafeValueContext.GetPowerShell)
            {
                // GetPowerShell does its own validation of allowed variables in the
                // context of the entire script block, and then supplies this visitor
                // with the CommandExpressionAst directly. This
                // prevents us from evaluating variable safety in this visitor,
                // so we rely on GetPowerShell's implementation.
                return true;
            }

            if (_safeValueContext == GetSafeValueVisitor.SafeValueContext.ModuleAnalysis)
            {
                return variableExpressionAst.IsConstantVariable() ||
                       (variableExpressionAst.VariablePath.IsUnqualified &&
                        variableExpressionAst.VariablePath.UnqualifiedPath.Equals(SpecialVariables.PSScriptRoot, StringComparison.OrdinalIgnoreCase));
            }

            bool unused = false;
            return variableExpressionAst.IsSafeVariableReference(null, ref unused);
        }

        public object VisitTypeExpression(TypeExpressionAst typeExpressionAst)
        {
            // Type expressions are not safe as they allow fingerprinting by providing
            // a set of types, you can inspect the types in the AppDomain implying which assemblies are in use
            // and their version
            return false;
        }

        public object VisitMemberExpression(MemberExpressionAst memberExpressionAst)
        {
            return false;
        }

        public object VisitArrayExpression(ArrayExpressionAst arrayExpressionAst)
        {
            // An Array expression *may* be safe, if its components are safe
            return arrayExpressionAst.SubExpression.Accept(this);
        }

        public object VisitArrayLiteral(ArrayLiteralAst arrayLiteralAst)
        {
            bool isSafe = arrayLiteralAst.Elements.All(e => (bool)e.Accept(this));
            // An array literal is safe
            return isSafe;
        }

        public object VisitHashtable(HashtableAst hashtableAst)
        {
            if (hashtableAst.KeyValuePairs.Count > MaxHashtableKeyCount)
            {
                return false;
            }

            return hashtableAst.KeyValuePairs.All(pair => (bool)pair.Item1.Accept(this) && (bool)pair.Item2.Accept(this));
        }

        public object VisitScriptBlockExpression(ScriptBlockExpressionAst scriptBlockExpressionAst)
        {
            // Returning a ScriptBlock instance itself is OK, bad stuff only happens
            // when invoking one (which is blocked)
            return true;
        }

        public object VisitParenExpression(ParenExpressionAst parenExpressionAst)
        {
            return parenExpressionAst.Pipeline.Accept(this);
        }
    }

}
