using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Data.Converters
{
    /// <summary>
    /// Converts data structures into PSD1 Strings
    /// </summary>
    public class HashtableConverter : IPsd1Converter
    {
        /// <summary>
        /// Converts to psd1 string
        /// </summary>
        /// <param name="Value">The object to convert</param>
        /// <param name="Depth">The indentation level</param>
        /// <param name="Converter">The conversion runtime object, including its settings.</param>
        /// <param name="Parents">The parent objects. Used in complex data types to prevent infinite recursion.</param>
        /// <returns>The converted PSD1 representation of the value provided</returns>
        public string Convert(object Value, object[] Parents, int Depth, Psd1Converter Converter)
        {
            object[] newParents = new object[] { Value };

            if (Parents != null)
            {
                if (Parents.Contains(Value))
                    return "'System.Collections.Hashtable (recursed)'";
                if (Converter.MaxDepth > 0 && Parents.Length >= Converter.MaxDepth)
                    return "'System.Collections.Hashtable'";

                List<object> newParentList = new List<object>();
                newParentList.AddRange(Parents);
                newParentList.Add(Value);
                newParents = newParentList.ToArray();
            }

            IDictionary value = (IDictionary)Value;

            string indent = new string(' ', Depth * 4);
            string newIndent = new string(' ', (Depth + 1) * 4);

            StringBuilder sb = new StringBuilder();
            sb.AppendLine("@{");

            foreach (object key in value.Keys)
                sb.AppendLine($"{newIndent}{CodeGeneration.EscapeSingleQuotedStringContent(LanguagePrimitives.ConvertTo<string>(key))} = {DataHost.Convert(value[key], newParents, Depth + 1, Converter)}");

            sb.Append($"{indent}}}");
            return sb.ToString();
        }
    }
}
