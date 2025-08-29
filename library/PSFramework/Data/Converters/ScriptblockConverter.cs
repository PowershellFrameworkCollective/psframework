using System;
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
    internal class ScriptblockConverter : IPsd1Converter
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
            ScriptBlock code = (ScriptBlock)Value;
            StringBuilder sb = new StringBuilder();
            sb.AppendLine("{");
            foreach (string line in code.Ast.Extent.Text.Substring(1, code.Ast.Extent.Text.Length - 2).Split('\n'))
                sb.AppendLine($"    {line}");
            sb.Append($"{new String(' ', 4 * Depth)}}}");

            return sb.ToString();
        }
    }
}
