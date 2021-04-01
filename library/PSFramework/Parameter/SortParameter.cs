using System;
using System.Collections;
using System.Management.Automation;
using System.Text.RegularExpressions;
using PSFramework.Utility;

namespace PSFramework.Parameter
{
    /// <summary>
    /// Input parser for wrapping around Sort-Object
    /// </summary>
    public class SortParameter : ParameterClass
    {
        /// <summary>
        /// The value passed to Sort-Object
        /// </summary>
        public object Value;

        /// <summary>
        /// Parse Input strings
        /// </summary>
        /// <param name="Property">The string to parse as property to sort by</param>
        public SortParameter(string Property)
        {
            if (!Regex.IsMatch(Property, "[<>\\.]"))
            {
                Value = Property;
                return;
            }

            Hashtable dictionary = new Hashtable(StringComparer.InvariantCultureIgnoreCase);
            if (UtilityHost.IsLike(Property, ">*"))
            {
                dictionary["Descending"] = true;
                Property = Property.Substring(1).Trim();
            }
            if (UtilityHost.IsLike(Property, "<*"))
            {
                dictionary["Descending"] = false;
                Property = Property.Substring(1).Trim();
            }
            if (UtilityHost.IsLike(Property, "*.*"))
                dictionary["Expression"] = ScriptBlock.Create($"$_.{Property}");
            else
                dictionary["Expression"] = Property;
            Value = dictionary;
        }

        /// <summary>
        /// Any other input is passed straight through
        /// </summary>
        /// <param name="InputObject">The input object to pass through</param>
        public SortParameter(object InputObject)
        {
            Value = InputObject;
        }

        /// <summary>
        /// Returns the string representation of the resultant sort property
        /// </summary>
        /// <returns>Some text</returns>
        public override string ToString()
        {
            return Value?.ToString();
        }
    }
}
