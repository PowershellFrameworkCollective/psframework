using PSFramework.Utility;
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
    public class CustomConverter : IPsd1Converter
    {
        /// <summary>
        /// The type the custom converter is assigned to
        /// </summary>
        public Type AssignedType;

        /// <summary>
        /// The code calculating the new PSD1-String
        /// </summary>
        public PsfScriptBlock Code;

        /// <summary>
        /// Any additional properties to assign to this.
        /// These properties are made available to the code via the $this variable
        /// </summary>
        public Hashtable Properties = new Hashtable(StringComparer.OrdinalIgnoreCase);

        /// <summary>
        /// The result to return as a default.
        /// This is mostly used in combination with "OnErrorDefault"
        /// </summary>
        public string DefaultResult = "$null";

        /// <summary>
        /// Whether in case of an error it should just return a default string, rather than failing the entire conversion.
        /// </summary>
        public bool OnErrorDefault = false;

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
            Hashtable data = new Hashtable(StringComparer.OrdinalIgnoreCase);
            data["Converter"] = Converter;
            data["Properties"] = Properties;
            data["Depth"] = Depth;
            data["Parents"] = Parents;
            data["Value"] = Value;

            System.Collections.ObjectModel.Collection<PSObject> results = null;
            try { results = Code.InvokeEx(false, Value, Value, data, false, false, Depth, Converter); }
            catch (Exception e) {
                Converter.WriteVerbose($"Custom Converter Error. Assigned Type: {AssignedType.Name} | Data: {Value} | Error: {e.Message}");
                if (OnErrorDefault)
                    return DefaultResult;
                throw e;
            }

            if (results.Count < 1)
            {
                Converter.WriteVerbose($"Custom Converter Failed. Assigned Type: {AssignedType.Name} | Data: {Value} | No results returned");
                if (OnErrorDefault)
                    return DefaultResult;
                throw new InvalidOperationException("Custom converter returned no content!");
            }
            if (String.IsNullOrEmpty(LanguagePrimitives.ConvertTo<string>(results[0].BaseObject)))
            {
                Converter.WriteVerbose($"Custom Converter Failed. Assigned Type: {AssignedType.Name} | Data: {Value} | Results is null or empty");
                if (OnErrorDefault)
                    return DefaultResult;
                throw new InvalidOperationException("Custom converter returned null or an empty string!");
            }

            return LanguagePrimitives.ConvertTo<string>(results[0].BaseObject);
        }

        /// <summary>
        /// Creates a new custom converter
        /// </summary>
        /// <param name="AssignedType">The type that should be converted</param>
        /// <param name="Code">The code doing the conversion</param>
        public CustomConverter(Type AssignedType, PsfScriptBlock Code)
        {
            this.AssignedType = AssignedType;
            this.Code = Code;
        }
    }
}
