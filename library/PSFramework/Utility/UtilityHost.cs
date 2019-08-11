using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Management.Automation;
using System.Net;
using System.Net.NetworkInformation;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;

using PSFramework.Localization;

namespace PSFramework.Utility
{
    /// <summary>
    /// Contains static resources of various kinds. Primarily for internal consumption.
    /// </summary>
    public static class UtilityHost
    {
        /// <summary>
        /// The ID for the primary (or front end) Runspace. Used for stuff that should only happen on the user-runspace.
        /// </summary>
        public static Guid PrimaryRunspace;

        /// <summary>
        /// The number of digits a size object shows by default
        /// </summary>
        public static int SizeDigits = 2;

        /// <summary>
        /// The way size objects are usually displayed
        /// </summary>
        public static SizeStyle SizeStyle = SizeStyle.Dynamic;
        
        /// <summary>
        /// Tests whether a given string is the local host.
        /// Does NOT use DNS resolution, DNS aliases will NOT be recognized!
        /// </summary>
        /// <param name="Name">The name to test for being local host</param>
        /// <returns>Whether the name is localhost</returns>
        public static bool IsLocalhost(string Name)
        {
            #region Handle IP Addresses
            try
            {
                IPAddress tempAddress;
                IPAddress.TryParse(Name, out tempAddress);
                if (IPAddress.IsLoopback(tempAddress))
                    return true;

                foreach (NetworkInterface netInterface in NetworkInterface.GetAllNetworkInterfaces())
                {
                    IPInterfaceProperties ipProps = netInterface.GetIPProperties();
                    foreach (UnicastIPAddressInformation addr in ipProps.UnicastAddresses)
                    {
                        if (tempAddress.ToString() == addr.Address.ToString())
                            return true;
                    }
                }
            }
            catch { }
            #endregion Handle IP Addresses

            #region Handle Names
            try
            {
                if (Name == ".")
                    return true;
                if (Name.ToLower() == "localhost")
                    return true;
                if (Name.ToLower() == Environment.MachineName.ToLower())
                    return true;
                if (Name.ToLower() == (Environment.MachineName + "." + Environment.GetEnvironmentVariable("USERDNSDOMAIN")).ToLower())
                    return true;
            }
            catch { }
            #endregion Handle Names
            return false;
        }

        /// <summary>
        /// Tests whether a given string is a valid target for targeting as a computer. Will first convert from idn name.
        /// </summary>
        public static bool IsValidComputerTarget(string ComputerName)
        {
            try
            {
                System.Globalization.IdnMapping mapping = new System.Globalization.IdnMapping();
                string temp = mapping.GetAscii(ComputerName);
                return Regex.IsMatch(temp, RegexHelper.ComputerTarget);
            }
            catch { return false; }
        }

        /// <summary>
        /// Implement's VB's Like operator logic.
        /// </summary>
        public static bool IsLike(string String, string Pattern, bool CaseSensitive = false)
        {
            if (!CaseSensitive)
            {
                String = String.ToLower();
                Pattern = Pattern.ToLower();
            }

            // Characters matched so far
            int matched = 0;

            // Loop through pattern string
            for (int i = 0; i < Pattern.Length;)
            {
                // Check for end of string
                if (matched > String.Length)
                    return false;

                // Get next pattern character
                char c = Pattern[i++];
                if (c == '[') // Character list
                {
                    // Test for exclude character
                    bool exclude = (i < Pattern.Length && Pattern[i] == '!');
                    if (exclude)
                        i++;
                    // Build character list
                    int j = Pattern.IndexOf(']', i);
                    if (j < 0)
                        j = String.Length;
                    HashSet<char> charList = CharListToSet(Pattern.Substring(i, j - i));
                    i = j + 1;

                    if (charList.Contains(String[matched]) == exclude)
                        return false;
                    matched++;
                }
                else if (c == '?') // Any single character
                {
                    matched++;
                }
                else if (c == '#') // Any single digit
                {
                    if (!Char.IsDigit(String[matched]))
                        return false;
                    matched++;
                }
                else if (c == '*') // Zero or more characters
                {
                    if (i < Pattern.Length)
                    {
                        // Matches all characters until
                        // next character in pattern
                        char next = Pattern[i];
                        int j = String.IndexOf(next, matched);
                        if (j < 0)
                            return false;
                        matched = j;
                    }
                    else
                    {
                        // Matches all remaining characters
                        matched = String.Length;
                        break;
                    }
                }
                else // Exact character
                {
                    if (matched >= String.Length || c != String[matched])
                        return false;
                    matched++;
                }
            }
            // Return true if all characters matched
            return (matched == String.Length);
        }

        /// <summary>
        /// Converts a string of characters to a HashSet of characters. If the string
        /// contains character ranges, such as A-Z, all characters in the range are
        /// also added to the returned set of characters.
        /// </summary>
        /// <param name="charList">Character list string</param>
        private static HashSet<char> CharListToSet(string charList)
        {
            HashSet<char> set = new HashSet<char>();

            for (int i = 0; i < charList.Length; i++)
            {
                if ((i + 1) < charList.Length && charList[i + 1] == '-')
                {
                    // Character range
                    char startChar = charList[i++];
                    i++; // Hyphen
                    char endChar = (char)0;
                    if (i < charList.Length)
                        endChar = charList[i++];
                    for (int j = startChar; j <= endChar; j++)
                        set.Add((char)j);
                }
                else set.Add(charList[i]);
            }
            return set;
        }

        /// <summary>
        /// Compress string using default zip algorithms
        /// </summary>
        /// <param name="String">The string to compress</param>
        /// <returns>Returns a compressed string.</returns>
        public static string CompressString(string String)
        {
            byte[] bytes = Encoding.UTF8.GetBytes(String);
            using (MemoryStream outputStream = new MemoryStream())
            using (GZipStream gZipStream = new GZipStream(outputStream, CompressionMode.Compress))
            {
                gZipStream.Write(bytes, 0, bytes.Length);
                gZipStream.Close();
                outputStream.Close();
                return Convert.ToBase64String(outputStream.ToArray());
            }
        }

        /// <summary>
        /// Expand a string using default zig algorithms
        /// </summary>
        /// <param name="CompressedString">The compressed string to expand</param>
        /// <returns>Returns an expanded string.</returns>
        public static string ExpandString(string CompressedString)
        {
            using (MemoryStream inputStream = new MemoryStream(Convert.FromBase64String(CompressedString)))
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

        /// <summary>
        /// Returns the execution context for the current runspace based on the current thread.
        /// </summary>
        /// <returns>The current execution context</returns>
        public static object GetExecutionContextFromTLS()
        {
            Type pipelineType = typeof(PowerShell).Assembly.GetType("System.Management.Automation.Runspaces.LocalPipeline");
            MethodInfo method = pipelineType.GetMethod("GetExecutionContextFromTLS", BindingFlags.Static | BindingFlags.NonPublic);
            return method.Invoke(null, BindingFlags.NonPublic | BindingFlags.Static, null, null, System.Globalization.CultureInfo.CurrentCulture);
        }

        /// <summary>
        /// Returns the list of runspaces available in the process
        /// </summary>
        /// <returns>The lists of currently known runspaces</returns>
        public static ICollection<System.Management.Automation.Runspaces.Runspace> GetRunspaces()
        {
            Type runspaceType = typeof(System.Management.Automation.Runspaces.Runspace);
            MethodInfo method = runspaceType.GetMethod("get_RunspaceList", BindingFlags.Static | BindingFlags.NonPublic);
            return (ICollection < System.Management.Automation.Runspaces.Runspace > )method.Invoke(null, null);
        }

        /// <summary>
        /// Removes an alias from the global list of aliases
        /// </summary>
        /// <param name="Name">The name of the laias to kill</param>
        /// <param name="Force">Whether to remove ReadOnly items</param>
        public static void RemovePowerShellAlias(string Name, bool Force)
        {
            object context = GetExecutionContextFromTLS();
            object topLevelState = GetPrivateProperty("TopLevelSessionState", context);
            object globalScope = GetPrivateProperty("GlobalScope", topLevelState);
            Dictionary<string, AliasInfo> aliases = (Dictionary<string, AliasInfo>)GetPrivateField("_alias", globalScope);

            if (!aliases.ContainsKey(Name))
                throw new ItemNotFoundException(String.Format(LocalizationHost.Read("PSFramework.Assembly.UtilityHost.AliasNotFound"), Name));

            AliasInfo alias = aliases[Name];

            if ((alias.Options & ScopedItemOptions.Constant) != 0)
                throw new InvalidOperationException(String.Format(LocalizationHost.Read("PSFramework.Assembly.UtilityHost.AliasProtected"), Name));
            if (!Force && ((alias.Options & ScopedItemOptions.ReadOnly) != 0))
                throw new InvalidOperationException(String.Format(LocalizationHost.Read("PSFramework.Assembly.UtilityHost.AliasReadOnly"), Name));
            
            aliases.Remove(Name);
        }

        /// <summary>
        /// Returns the value of a private property on an object
        /// </summary>
        /// <param name="Name">The name of the property</param>
        /// <param name="Instance">The object from which to read the property from</param>
        /// <returns>The value of the property content (may be null)</returns>
        public static object GetPrivateProperty(string Name, object Instance)
        {
            if (Instance == null)
                return null;

            PropertyInfo property = Instance.GetType().GetProperty(Name, BindingFlags.Instance | BindingFlags.NonPublic);
            if (property == null)
                throw new ArgumentException(String.Format(LocalizationHost.Read("PSFramework.Assembly.UtilityHost.PrivatePropertyNotFound"), Name), "Name");
            return property.GetValue(Instance);
        }

        /// <summary>
        /// Returns the value of a public property on an object
        /// </summary>
        /// <param name="Name">The name of the property</param>
        /// <param name="Instance">The object from which to read the property from</param>
        /// <returns>The value of the property content (may be null)</returns>
        public static object GetPublicProperty(string Name, object Instance)
        {
            if (Instance == null)
                return null;

            PropertyInfo property = Instance.GetType().GetProperty(Name, BindingFlags.Instance | BindingFlags.Public);
            if (property == null)
                throw new ArgumentException(String.Format(LocalizationHost.Read("PSFramework.Assembly.UtilityHost.PrivatePropertyNotFound"), Name), "Name");
            return property.GetValue(Instance);
        }

        /// <summary>
        /// Returns the value of a private static property on a type
        /// </summary>
        /// <param name="StaticType">The type to pick from</param>
        /// <param name="Name">The name of the property to retrieve</param>
        /// <returns>The value of the property content (may be null)</returns>
        public static object GetPrivateStaticProperty(Type StaticType, string Name)
        {
            PropertyInfo property = StaticType.GetProperty(Name, BindingFlags.Static | BindingFlags.NonPublic);
            if (property == null)
                throw new ArgumentException(LocalizationHost.Read(String.Format("PSFramework.Assembly.UtilityHost.PrivatePropertyNotFound", Name)), "Name");
            return property.GetValue(null, BindingFlags.NonPublic | BindingFlags.Static, null, null, System.Globalization.CultureInfo.CurrentCulture);
        }

        /// <summary>
        /// Returns the value of a private field on an object
        /// </summary>
        /// <param name="Name">The name of the field</param>
        /// <param name="Instance">The object from which to read the field from</param>
        /// <returns>The value of the field content (may be null)</returns>
        public static object GetPrivateField(string Name, object Instance)
        {
            if (Instance == null)
                return null;

            FieldInfo property = Instance.GetType().GetField(Name, BindingFlags.Instance | BindingFlags.NonPublic);
            if (property == null)
                throw new ArgumentException(LocalizationHost.Read(String.Format("PSFramework.Assembly.UtilityHost.PrivateFieldNotFound", Name)), "Name");
            return property.GetValue(Instance);
        }

        /// <summary>
        /// Returns a static private method of a type
        /// </summary>
        /// <param name="StaticType">The type to search in</param>
        /// <param name="Name">The name of the method to retrieve</param>
        /// <returns>The method object requested</returns>
        public static MethodInfo GetPrivateStaticMethod(Type StaticType, string Name)
        {
            MethodInfo method = StaticType.GetMethod(Name, BindingFlags.Static | BindingFlags.NonPublic);
            if (method == null)
                throw new ArgumentException(LocalizationHost.Read(String.Format("PSFramework.Assembly.UtilityHost.PrivateMethodNotFound", Name)), "Name");
            return method;
        }

        /// <summary>
        /// Returns the current callstack
        /// </summary>
        public static IEnumerable<CallStackFrame> Callstack
        {
            get
            {
                // Works on PS4+
                try { return _CallstackNew; }

                // Needed for PS3
                catch { return _CallstackOld; }
            }
        }

        /// <summary>
        /// Returns the current callstack on PS4+
        /// </summary>
        private static IEnumerable<CallStackFrame> _CallstackNew
        {
            get
            {
                return System.Management.Automation.Runspaces.Runspace.DefaultRunspace.Debugger.GetCallStack();
            }
        }

        /// <summary>
        /// Returns the current callstack on PS3
        /// </summary>
        private static IEnumerable<CallStackFrame> _CallstackOld
        {
            get
            {
                MethodInfo method = System.Management.Automation.Runspaces.Runspace.DefaultRunspace.Debugger.GetType().GetMethod("GetCallStack", BindingFlags.NonPublic | BindingFlags.Instance);
                return (IEnumerable<CallStackFrame>)method.Invoke(System.Management.Automation.Runspaces.Runspace.DefaultRunspace.Debugger, null);
            }
        }

        /// <summary>
        /// Stored scriptblocks that can be retrieved on demand anywhere within the process
        /// </summary>
        public static ConcurrentDictionary<string, ScriptBlockItem> ScriptBlocks = new ConcurrentDictionary<string, ScriptBlockItem>(StringComparer.InvariantCultureIgnoreCase);
    }
}
