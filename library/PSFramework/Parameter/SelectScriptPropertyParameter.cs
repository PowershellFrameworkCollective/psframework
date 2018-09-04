using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Text.RegularExpressions;

namespace PSFramework.Parameter
{
    /// <summary>
    /// Parameter class that handles script property input
    /// </summary>
    [ParameterClass]
    public class SelectScriptPropertyParameter : ParameterClass
    {
        /// <summary>
        /// The actual properties
        /// </summary>
        public List<PSScriptProperty> Value = new List<PSScriptProperty>();

        /// <summary>
        /// Create a script property from a script property
        /// </summary>
        /// <param name="Property">The property to add</param>
        public SelectScriptPropertyParameter(PSScriptProperty Property)
        {
            InputObject = Property;
            Value.Add(Property);
        }

        /// <summary>
        /// Create a script property from a string
        /// </summary>
        /// <param name="StringValue">The string to interpret into a scriptproperty</param>
        public SelectScriptPropertyParameter(string StringValue)
        {
            InputObject = StringValue;
            if (!Regex.IsMatch(StringValue, " := "))
                throw new ArgumentException(String.Format("Failed to parse '{0}' as ScriptProperty!", StringValue));
            if (Regex.IsMatch(StringValue, " := .*? =: "))
            {
                Match match = Regex.Match(StringValue, "^(.*?) := (.*?) =: (.*?)$");
                Value.Add(new PSScriptProperty(match.Groups[1].Value, ScriptBlock.Create(ExpandScriptString(match.Groups[2].Value)), ScriptBlock.Create(ExpandScriptString(match.Groups[3].Value))));
            }
            else
            {
                Match match = Regex.Match(StringValue, "^(.*?) := (.*?)$");
                Value.Add(new PSScriptProperty(match.Groups[1].Value, ScriptBlock.Create(ExpandScriptString(match.Groups[2].Value))));
            }
        }

        /// <summary>
        /// Create one or multiple script properties from hashtable
        /// </summary>
        /// <param name="Hashtable">The hashtable to build from</param>
        public SelectScriptPropertyParameter(Hashtable Hashtable)
        {
            InputObject = Hashtable;
            foreach (string key in Hashtable.Keys)
            {
                if (Hashtable[key] is ScriptBlock)
                    Value.Add(new PSScriptProperty(key, (ScriptBlock)Hashtable[key]));
                else if (Hashtable[key] is Hashtable)
                {
                    if (((Hashtable)Hashtable[key]).ContainsKey("get") && ((Hashtable)Hashtable[key]).ContainsKey("set"))
                        Value.Add(new PSScriptProperty(key, (ScriptBlock)((Hashtable)Hashtable[key])["get"], (ScriptBlock)((Hashtable)Hashtable[key])["set"]));
                    else
                        throw new ArgumentException(String.Format("{0}: Malformed Hashtable, cannot convert to scriptproperty", key));
                }
                else
                    throw new ArgumentException(String.Format("{0}: Unable to parse input as scriptproperty!", key));
            }
        }

        /// <summary>
        /// Print things to string
        /// </summary>
        /// <returns>The string representation of these properties</returns>
        public override string ToString()
        {
            List<string> strings = new List<string>();
            foreach (PSScriptProperty property in Value)
                strings.Add(String.Format("{0} := {{ {1} }} =: {{ {2} }}", property.Name, property.GetterScript, property.SetterScript));
            return String.Join(", ", strings);
        }

        private string ExpandScriptString(string ScriptString)
        {
            ParseError[] errors;
            Token[] tokens;
            Parser.ParseInput(ScriptString, out tokens, out errors);
            List<string> results = new List<string>();
            foreach (Token token in tokens)
            {
                // Commands without a dash character are assumed to be properties
                if (((token.TokenFlags & TokenFlags.CommandName) != 0) && (!token.Text.Contains("-")))
                    results.Add(String.Format("$this.{0}", token.Text));
                else
                    results.Add(token.Text);
            }
            return String.Join(" ", results);
        }
    }
}
