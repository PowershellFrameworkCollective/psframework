using System;
using System.Collections.Concurrent;
using System.IO;
using System.IO.Compression;
using System.Management.Automation;
using System.Reflection;
using System.Runtime.Serialization;
using System.Text;
using System.Text.RegularExpressions;
using System.Xml;
using System.Xml.Linq;

namespace PSFramework.Serialization
{
    /// <summary>
    /// Typeconverter that does the heavy lifting of maintaining type integrity across process borders.
    /// </summary>
    public class SerializationTypeConverter : PSTypeConverter
    {
        private static ResolveEventHandler AssemblyHandler = new ResolveEventHandler(CurrentDomain_AssemblyResolve);

        /// <summary>
        /// Whether the source can be converted to its destination
        /// </summary>
        /// <param name="sourceValue">The value to convert</param>
        /// <param name="destinationType">The type to convert to</param>
        /// <returns>Whether this action is possible</returns>
        public override bool CanConvertFrom(object sourceValue, Type destinationType)
        {
            byte[] array;
            Exception ex;
            return this.CanConvert(sourceValue, destinationType, out array, out ex);
        }

        /// <summary>
        /// Converts an object
        /// </summary>
        /// <param name="sourceValue">The data to convert</param>
        /// <param name="destinationType">The type to convert to</param>
        /// <param name="formatProvider">This will be ignored, but must be present</param>
        /// <param name="ignoreCase">This will be ignored, but must be present</param>
        /// <returns>The converted object</returns>
        public override object ConvertFrom(object sourceValue, Type destinationType, IFormatProvider formatProvider, bool ignoreCase)
        {
            return this.DeserializeObject(sourceValue, destinationType);
        }

        /// <summary>
        /// Whether the input object can be converted to the Destination type
        /// </summary>
        /// <param name="sourceValue">Input value</param>
        /// <param name="destinationType">The type to convert to</param>
        /// <returns></returns>
        public override bool CanConvertTo(object sourceValue, Type destinationType)
        {
            byte[] array;
            Exception ex;
            return this.CanConvert(sourceValue, destinationType, out array, out ex);
        }

        /// <summary>
        /// Converts an object
        /// </summary>
        /// <param name="sourceValue">The data to convert</param>
        /// <param name="destinationType">The type to convert to</param>
        /// <param name="formatProvider">This will be ignored, but must be present</param>
        /// <param name="ignoreCase">This will be ignored, but must be present</param>
        /// <returns>The converted object</returns>
        public override object ConvertTo(object sourceValue, Type destinationType, IFormatProvider formatProvider, bool ignoreCase)
        {
            return this.DeserializeObject(sourceValue, destinationType);
        }
        private bool CanConvert(object sourceValue, Type destinationType, out byte[] serializationData, out Exception error)
        {
            serializationData = null;
            error = null;
            if (destinationType == null)
            {
                error = new ArgumentNullException("destinationType");
                return false;
            }
            if (sourceValue == null)
            {
                error = new ArgumentNullException("sourceValue");
                return false;
            }
            PSObject pSObject = sourceValue as PSObject;
            if (pSObject == null)
            {
                error = new NotSupportedException(string.Format("Unsupported Source Type: {0}", sourceValue.GetType().FullName));
                return false;
            }
            if (!CanSerialize(destinationType))
            {
                error = new NotSupportedException(string.Format("Unsupported Type Conversion: {0}", destinationType.FullName));
                return false;
            }
            if (typeof(Exception).IsAssignableFrom(destinationType) && pSObject.TypeNames != null && pSObject.TypeNames.Count > 0 && pSObject.TypeNames[0].StartsWith("Deserialized.System.Management.Automation"))
            {
                foreach (string current in pSObject.TypeNames)
                {
                    if (current.Equals("Deserialized.System.Management.Automation.ParameterBindingException", StringComparison.OrdinalIgnoreCase))
                    {
                        return false;
                    }
                }
            }
            if (pSObject.Properties["SerializationData"] == null)
            {
                error = new NotSupportedException("Serialization Data is Absent");
                return false;
            }
            object value = pSObject.Properties["SerializationData"].Value;
            if (!(value is byte[]))
            {
                error = new NotSupportedException("Unsupported Data Format");
                return false;
            }
            serializationData = (value as byte[]);
            return true;
        }
        private object DeserializeObject(object sourceValue, Type destinationType)
        {
            byte[] buffer;
            Exception ex;
            if (!this.CanConvert(sourceValue, destinationType, out buffer, out ex))
            {
                throw ex;
            }
            object obj;

            AppDomain.CurrentDomain.AssemblyResolve += AssemblyHandler;
            try
            {
                obj = ConvertFromXml(ExpandString(buffer), destinationType);
                PSFCore.PSFCoreHost.WriteDebug("Serializer.DeserializeObject.Obj", obj);
                IDeserializationCallback deserializationCallback = obj as IDeserializationCallback;
                if (deserializationCallback != null)
                    deserializationCallback.OnDeserialization(sourceValue);
            }
            finally
            {
                AppDomain.CurrentDomain.AssemblyResolve -= AssemblyHandler;
            }
            return obj;
        }

        /// <summary>
        /// Registers an assembly resolving event
        /// </summary>
        public static void RegisterAssemblyResolver()
        {
            AppDomain.CurrentDomain.AssemblyResolve += AssemblyHandler;
        }
        private static Assembly CurrentDomain_AssemblyResolve(object sender, ResolveEventArgs args)
        {
            PSFCore.PSFCoreHost.WriteDebug("Serializer.AssemblyResolve.Sender", sender);
            PSFCore.PSFCoreHost.WriteDebug("Serializer.AssemblyResolve.Args", args);
            
            // 1) Match directly against existing assembly
            Assembly[] assemblies = AppDomain.CurrentDomain.GetAssemblies();
            for (int i = 0; i < assemblies.Length; i++)
                if (assemblies[i].FullName == args.Name)
                    return assemblies[i];

            // 2) Match by short-name
            string shortName = args.Name.Split(',')[0];
            if (AssemblyShortnameMapping.Count > 0 && AssemblyShortnameMapping[shortName])
                for (int i = 0; i < assemblies.Length; i++)
                    if (String.Equals(assemblies[i].FullName.Split(',')[0], shortName, StringComparison.InvariantCultureIgnoreCase))
                        return assemblies[i];

            if (AssemblyMapping.Count == 0)
                return null;

            // 3) Match directly against registered assembly
            foreach (string key in AssemblyMapping.Keys)
                if (key == args.Name)
                    return AssemblyMapping[key];

            // 4) Match by pattern against registered assembly
            foreach (string key in AssemblyMapping.Keys)
            {
                try
                {
                    if (Regex.IsMatch(args.Name, key, RegexOptions.IgnoreCase))
                        return AssemblyMapping[key];
                }
                catch { }
            }

            return null;
        }

        /// <summary>
        /// Whether an object can be serialized
        /// </summary>
        /// <param name="obj">The object to test</param>
        /// <returns>Whether the object can be serialized</returns>
        public static bool CanSerialize(object obj)
        {
            return obj != null && CanSerialize(obj.GetType());
        }

        /// <summary>
        /// Whether a type can be serialized
        /// </summary>
        /// <param name="type">The type to test</param>
        /// <returns>Whether the specified type can be serialized</returns>
        public static bool CanSerialize(Type type)
        {
            return TypeIsSerializable(type) && !type.IsEnum || (type.Equals(typeof(Exception)) || type.IsSubclassOf(typeof(Exception)));
        }

        /// <summary>
        /// The validation check on whether a type is serializable
        /// </summary>
        /// <param name="type">The type to test</param>
        /// <returns>Returns whether that type can be serialized</returns>
        public static bool TypeIsSerializable(Type type)
        {
            if (type == null)
            {
                throw new ArgumentNullException("type");
            }
            if (!type.IsSerializable)
            {
                return false;
            }
            if (!type.IsGenericType)
            {
                return true;
            }
            Type[] genericArguments = type.GetGenericArguments();
            for (int i = 0; i < genericArguments.Length; i++)
            {
                Type type2 = genericArguments[i];
                if (!TypeIsSerializable(type2))
                {
                    return false;
                }
            }
            return true;
        }

        /// <summary>
        /// Used to obtain the information to write
        /// </summary>
        /// <param name="psObject">The object to dissect</param>
        /// <returns>A memory stream.</returns>
        public static object GetSerializationData(PSObject psObject)
        {
            return CompressString(ConvertToXml(psObject.BaseObject));
        }

        /// <summary>
        /// Allows remapping assembly-names for objects being deserialized, using the full assembly-name.
        /// </summary>
        public static readonly ConcurrentDictionary<string, Assembly> AssemblyMapping = new ConcurrentDictionary<string, Assembly>(StringComparer.InvariantCultureIgnoreCase);
        /// <summary>
        /// Allows remapping assembly-names for objects being deserialized, using an abbreviated name only, to help avoid having to be version specific.
        /// </summary>
        public static readonly ConcurrentDictionary<string, bool> AssemblyShortnameMapping = new ConcurrentDictionary<string, bool>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Converts an object into XML
        /// </summary>
        /// <param name="Item">The object to serialize</param>
        /// <returns>The XML form of the object</returns>
        /// <exception cref="ArgumentNullException">$null objects are not accepted</exception>
        public static string ConvertToXml(object Item)
        {
            if (Item == null)
                throw new ArgumentNullException("item");

            string result;
            using (StringWriter writer = new StringWriter())
            using (XmlTextWriter xmlWriter = new XmlTextWriter(writer))
            {
                DataContractSerializer serializer = new DataContractSerializer(Item.GetType());
                serializer.WriteObject(xmlWriter, Item);
                result = writer.ToString();
            }
            return result;
        }

        /// <summary>
        /// Deserializes an XML object back into its object form
        /// </summary>
        /// <param name="Xml">The XML text to convert</param>
        /// <param name="ExpectedType">What type to convert to</param>
        /// <returns>The converted object</returns>
        public static object ConvertFromXml(string Xml, Type ExpectedType)
        {
            object result;
            using (StringReader reader = new StringReader(Xml))
            using (XmlTextReader xmlReader = new XmlTextReader(reader))
            {
                DataContractSerializer serializer = new DataContractSerializer(ExpectedType);
                result = serializer.ReadObject(xmlReader);
            }
            return result;
        }

        /// <summary>
        /// Compress string using default zip algorithms
        /// </summary>
        /// <param name="String">The string to compress</param>
        /// <returns>Returns a compressed string as byte-array.</returns>
        public static byte[] CompressString(string String)
        {
            byte[] bytes = Encoding.UTF8.GetBytes(String);
            using (MemoryStream outputStream = new MemoryStream())
            using (GZipStream gZipStream = new GZipStream(outputStream, CompressionMode.Compress))
            {
                gZipStream.Write(bytes, 0, bytes.Length);
                gZipStream.Close();
                outputStream.Close();
                return outputStream.ToArray();
            }
        }

        /// <summary>
        /// Expand a string using default zig algorithms
        /// </summary>
        /// <param name="CompressedString">The compressed string to expand</param>
        /// <returns>Returns an expanded string.</returns>
        public static string ExpandString(byte[] CompressedString)
        {
            using (MemoryStream inputStream = new MemoryStream(CompressedString))
            using (MemoryStream outputStream = new MemoryStream())
            using (GZipStream converter = new GZipStream(inputStream, CompressionMode.Decompress))
            {
                converter.CopyTo(outputStream);
                converter.Close();
                inputStream.Close();
                string result = Encoding.UTF8.GetString(outputStream.ToArray());
                outputStream.Close();
                return result;
            }
        }
    }
}
