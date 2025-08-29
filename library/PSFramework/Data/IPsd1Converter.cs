using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Data
{
    /// <summary>
    /// Ruleset for types implementing PSD1 Conversion
    /// </summary>
    public interface IPsd1Converter
    {
        /// <summary>
        /// Convert an object to the string to insert into a psd1 document.
        /// </summary>
        /// <param name="Value">The value to convert</param>
        /// <param name="Parents">The parent objects. Used in complex data types to prevent infinite recursion.</param>
        /// <param name="Depth">The current indentation depth. Can be ignored for plain value returns, if you do not need to return multiple lines.</param>
        /// <param name="Converter">The conversion runtime object, including its settings.</param>
        /// <returns>The converted PSD1 representation of the value provided</returns>
        string Convert(object Value, object[] Parents, int Depth, Psd1Converter Converter);
    }
}
