using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Data.Converters
{
    /// <summary>
    /// Converts data structures into PSD1 Strings
    /// </summary>
    public class ArrayConverter : IPsd1Converter
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
            StringBuilder sb = new StringBuilder();
            string indent = new string(' ', Depth * 4);
            string newIndent = new string(' ', (Depth + 1) * 4);
            sb.AppendLine("@(");

            foreach (object item in (IEnumerable)Value)
                sb.AppendLine($"{newIndent}{DataHost.Convert(item, Parents, Depth + 1, Converter)}");

            sb.Append($"{indent})");
            return sb.ToString();
        }
    }
}
