using System;
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
    public class DBNullConverter : IPsd1Converter
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
            return "$null";
        }
    }
}
