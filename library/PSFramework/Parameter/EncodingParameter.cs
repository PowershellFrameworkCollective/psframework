using System;
using System.Management.Automation;
using System.Reflection;
using System.Text;

namespace PSFramework.Parameter
{
    /// <summary>
    /// Class that interprets input as an encoding
    /// </summary>
    public class EncodingParameter : ParameterClass
    {
        /// <summary>
        /// The parsed encoding to use.
        /// </summary>
        [ParameterContract(ParameterContractType.Field, ParameterContractBehavior.Mandatory)]
        public Encoding Encoding;

        /// <summary>
        /// Implicitly convert the value to an encoding object
        /// </summary>
        /// <param name="Parameter">The parameterclass object to convert</param>
        [ParameterContract(ParameterContractType.Operator, ParameterContractBehavior.Conversion)]
        public static implicit operator Encoding(EncodingParameter Parameter)
        {
            return Parameter.Encoding;
        }

        /// <summary>
        /// Implicitly convert encoding to the parameterclass by calling the correct constructor
        /// </summary>
        /// <param name="Encoding">The encoding to encapsule</param>
        [ParameterContract(ParameterContractType.Operator, ParameterContractBehavior.Conversion)]
        public static implicit operator EncodingParameter(Encoding Encoding)
        {
            return new EncodingParameter(Encoding);
        }

        /// <summary>
        /// Encapsule an encoding object in the parameter class
        /// </summary>
        /// <param name="Encoding">The encoding to wrap</param>
        public EncodingParameter(Encoding Encoding)
        {
            this.Encoding = Encoding;
            InputObject = Encoding;
        }

        /// <summary>
        /// Converts a string value to encoding
        /// </summary>
        /// <param name="EncodingString">A string value to interpret as encoding.</param>
        public EncodingParameter(string EncodingString)
        {
            InputObject = EncodingString;
            Encoding = GetEncoding(EncodingString);
        }

        /// <summary>
        /// Convert just about anything to encoding if registered.
        /// </summary>
        /// <param name="InputObject">The object to convert</param>
        public EncodingParameter(object InputObject)
        {
            if (InputObject == null)
                throw new ArgumentException("Input must not be null");

            PSObject input = new PSObject(InputObject);
            this.InputObject = InputObject;

            string key = "";

            foreach (string name in input.TypeNames)
            {
                if (_PropertyMapping.ContainsKey(name.ToLower()))
                {
                    key = name.ToLower();
                    break;
                }
            }

            if (key == "")
                throw new ArgumentException(String.Format("Could not interpret {0}", InputObject.GetType().FullName));

            foreach (string property in _PropertyMapping[key])
            {
                if (input.Properties[property] != null && input.Properties[property].Value != null && !String.IsNullOrEmpty(input.Properties[property].Value.ToString()))
                {
                    if (input.Properties[property].Value is Encoding)
                        Encoding = (Encoding)input.Properties[property].Value;
                    else
                        Encoding = (new EncodingParameter(input.Properties[property].Value.ToString())).Encoding;
                    break;
                }
            }
        }

        /// <summary>
        /// Returns the correct encoding for a given string
        /// </summary>
        /// <param name="Text">The string to convert to encoding</param>
        /// <returns>The encoding to retrieve.</returns>
        private Encoding GetEncoding(string Text)
        {
            switch (Text.ToLower())
            {
                case "unicode":
                    return Encoding.Unicode;
                case "bigendianunicode":
                    return Encoding.BigEndianUnicode;
                case "utf8":
                    return new UTF8Encoding(true);
                case "utf8bom":
                    return new UTF8Encoding(true);
                case "utf8nobom":
                    return new UTF8Encoding(false);
                case "utf7":
                    return Encoding.UTF7;
                case "utf32":
                    return Encoding.UTF32;
                case "ascii":
                    return Encoding.ASCII;
                case "default":
                    return Encoding.Default;
                case "oem":
                    return Encoding.UTF8;
                case "bigendianutf32":
                    return Encoding.GetEncoding("utf-32BE");
                default:
                    return Encoding.GetEncoding(Text);
            }
        }

        /// <summary>
        /// Returns the user-expected string from the specified encoding.
        /// "Expected" in the context of PowerShell usage.
        /// </summary>
        /// <param name="EncodingItem">The item to convert to string</param>
        /// <returns>The powershell string representation</returns>
        private string GetEncodingString(Encoding EncodingItem)
        {
            if (EncodingItem.BodyName == Encoding.Default.BodyName)
                return "Default";

            switch (EncodingItem.BodyName)
            {
                case "utf-16":
                    return "Unicode";
                case "utf-16BE":
                    return "BigEndianUnicode";
                case "utf-8":
                    if (IsUTF8BOM(EncodingItem))
                        return "UTF8";
                    return "UTF8NoBom";
                case "utf-7":
                    return "UTF7";
                case "utf-32":
                    return "UTF32";
                case "us-ascii":
                    return "ASCII";
                case "utf-32BE":
                    return "BigEndianUTF32";
                default:
                    return EncodingItem.BodyName;
            }
        }

        /// <summary>
        /// String representation of the parameter class
        /// </summary>
        /// <returns>The returned encoding string</returns>
        public override string ToString()
        {
            return GetEncodingString(Encoding);
        }

        /// <summary>
        /// Accepts a UTF8 encoding and returns, whether it includes writing a ByteOrderMark
        /// </summary>
        /// <param name="Encoding">The encoding object to interpret</param>
        /// <returns>Whether it is with BOM or without</returns>
        public static bool IsUTF8BOM(Encoding Encoding)
        {
            if (Encoding.BodyName != "utf-8")
                throw new ArgumentException("Not a utf-8 encoding!");
            Type type = Encoding.GetType();
            FieldInfo info = type.GetField("emitUTF8Identifier", BindingFlags.Instance | BindingFlags.NonPublic);
            return (bool)info.GetValue(Encoding);
        }
    }
}
