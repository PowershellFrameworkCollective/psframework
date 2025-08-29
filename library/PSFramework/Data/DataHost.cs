using PSFramework.Data.Converters;
using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Language;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Data
{
    /// <summary>
    /// Global Helper Tools for dealing with Data
    /// </summary>
    public static class DataHost
    {
        /// <summary>
        /// The registered list of PSD1 converters
        /// </summary>
        public static Dictionary<Type, IPsd1Converter> Converters = new Dictionary<Type, IPsd1Converter>();

        /// <summary>
        /// The fallback converter to use when all else fails
        /// </summary>
        public static IPsd1Converter DefaultConverter { get; internal set; }

        /// <summary>
        /// The converter to use for dictionaries, such as Hashtables
        /// </summary>
        public static IPsd1Converter DictionaryConverter { get; internal set; }

        /// <summary>
        /// Convert an object to the string to insert into a psd1 document.
        /// </summary>
        /// <param name="Value">The value to convert</param>
        /// <param name="Parents">The parent objects. Used in complex data types to prevent infinite recursion.</param>
        /// <param name="Depth">The current indentation depth. Can be ignored for plain value returns, if you do not need to return multiple lines.</param>
        /// <param name="Converter">The conversion runtime object, including its settings.</param>
        /// <returns>The converted PSD1 representation of the value provided</returns>
        public static string Convert(object Value, object[] Parents, int Depth, Psd1Converter Converter)
        {
            if (null == Value)
                return "$null";
            Converter.WriteVerbose($"Processing {Value.GetType().FullName}");
            if (Value as Enum != null)
                return $"'{CodeGeneration.EscapeSingleQuotedStringContent(Value.ToString())}'";
            if (Converters.ContainsKey(Value.GetType()))
                return Converters[Value.GetType()].Convert(Value, Parents, Depth, Converter);

            if (typeof(IDictionary).IsAssignableFrom(Value.GetType()))
                return DictionaryConverter.Convert(Value, Parents, Depth, Converter);

            // This will ensure both parent types and Interfaces apply properly
            foreach (Type key in Converters.Keys)
                if (key.IsAssignableFrom(Value.GetType()))
                    return Converters[key].Convert(Value, Parents, Depth, Converter);

            // This will be ugly. Probably.
            return DefaultConverter.Convert(Value, Parents, Depth, Converter);
        }

        /// <summary>
        /// Resets the PSD1 Converters to their default state
        /// </summary>
        public static void ResetConverters()
        {
            Converters = new Dictionary<Type, IPsd1Converter>();
            Initialize();
        }

        internal static void Initialize()
        {
            Converters[typeof(Int16)] = new IntConverter();
            Converters[typeof(Int32)] = new IntConverter();
            Converters[typeof(Int64)] = new IntConverter();
            Converters[typeof(UInt16)] = new IntConverter();
            Converters[typeof(UInt32)] = new IntConverter();
            Converters[typeof(UInt64)] = new IntConverter();
            Converters[typeof(Double)] = new DoubleConverter();
            Converters[typeof(float)] = new DoubleConverter();
            Converters[typeof(Boolean)] = new BoolConverter();
            Converters[typeof(SwitchParameter)] = new SwitchConverter();
            Converters[typeof(DBNull)] = new DBNullConverter();
            Converters[typeof(DateTime)] = new DateTimeConverter();
            Converters[typeof(TimeSpan)] = new TimeSpanConverter();
            Converters[typeof(Guid)] = new GuidConverter();
            Converters[typeof(Version)] = new VersionConverter();
            Converters[typeof(String)] = new TextConverter();
            Converters[typeof(Char)] = new TextConverter();
            Converters[typeof(Uri)] = new TextConverter();
            Converters[typeof(Assembly)] = new AssemblyConverter();
            Converters[typeof(TypeInfo)] = new TypeInfoConverter();
            Converters[typeof(ProviderInfo)] = new PSProviderInfoConverter();
            Converters[typeof(PSDriveInfo)] = new PSDriveInfoConverter();
            Converters[typeof(ICollection)] = new ArrayConverter();
            Converters[typeof(FileInfo)] = new FileSystemInfoConverter();
            Converters[typeof(DirectoryInfo)] = new FileSystemInfoConverter();
            Converters[typeof(ScriptBlock)] = new ScriptblockConverter();

            DictionaryConverter = new HashtableConverter();
            Converters[typeof(PSCustomObject)] = new PSObjectConverter();
            DefaultConverter = new PSObjectConverter();
        }
    }
}
