using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Runtime.Serialization;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Parameter
{
    /// <summary>
    /// Base class for parameter classes related to filesystem path validation
    /// </summary>
    [ParameterClass]
    public abstract class PathFileSystemParameterBase : ArrayList
    {
        /// <summary>
        /// The original item presented as input
        /// </summary>
        [ParameterContract(ParameterContractType.Field, ParameterContractBehavior.Mandatory)]
        public object InputObject;

        /// <summary>
        /// The input that failed
        /// </summary>
        [ParameterContract(ParameterContractType.Field, ParameterContractBehavior.Mandatory)]
        public List<object> FailedInput = new List<object>();

        #region Static tools
        /// <summary>
        /// Contains the list of property mappings.
        /// Types can be registered to it, allowing the parameter class to blindly interpret unknown types
        /// </summary>
        internal static ConcurrentDictionary<string, List<string>> _PropertyMapping = new ConcurrentDictionary<string, List<string>>(StringComparer.InvariantCultureIgnoreCase);

        /// <summary>
        /// Assigns a property mapping for a given type, allowing the parameter class to handle unknown types
        /// </summary>
        /// <param name="Name">The name of the type. Use the FullName of the type</param>
        /// <param name="PropertyName">The property names to register. When parsing input, it will move down this list until a valid property was found</param>
        public static void SetTypePropertyMapping(string Name, List<string> PropertyName)
        {
            _PropertyMapping[Name] = PropertyName;
        }
        #endregion Static tools

        /// <summary>
        /// Add a value if it is not yet included.
        /// Silently ignores values already in the ArrayList
        /// </summary>
        /// <param name="Path"></param>
        internal void AddEx(string Path)
        {
            if (Contains(Path))
                return;
            Add(Path);
        }

        internal List<string> ResolveFileSystemPath(string Path, bool IncludeFile, bool IncludeDirectory, bool Terminate, bool Resolve = true)
        {
            List<string> paths = new List<string>();

            SessionState state = new SessionState();
            IEnumerable<string> resolved = new Collection<string>();
            if (Resolve)
                resolved = state.Path.GetResolvedPSPathFromPSPath(Path).Where(o => o.Provider.Name == "FileSystem").Select(o => o.ProviderPath);
            else
                ((Collection<string>)resolved).Add(state.Path.GetUnresolvedProviderPathFromPSPath(Path));
            
            if (IncludeFile)
            {
                IEnumerable<string> files = resolved.Where(o => File.Exists(o));
                if (files.Count() > 0)
                    foreach (string file in files)
                        paths.Add(file);
                else if (!IncludeDirectory)
                {
                    if (Terminate)
                        throw new ArgumentException($"Invalid input: Did not resolve into files: {Path}");
                    else
                        FailedInput.Add(Path);
                }
            }
            if (IncludeDirectory)
            {
                IEnumerable<string> directories = resolved.Where(o => Directory.Exists(o));
                if (directories.Count() > 0)
                    foreach (string directory in directories)
                        paths.Add(directory);
                else if (!IncludeFile)
                {
                    if (Terminate)
                        throw new ArgumentException($"Invalid input: Did not resolve into directories: {Path}");
                    else
                        FailedInput.Add(Path);
                }
            }
            if (paths.Count == 0)
            {
                if (Terminate)
                    throw new ArgumentException($"Invalid input: Did not resolve into files or directories: {Path}");
                FailedInput.Add(Path);
                return paths;
            }

            return paths;
        }

        internal object GetObject(object Input)
        {
            if (_PropertyMapping.Count == 0)
                return Input;

            PSObject obj = PSObject.AsPSObject(Input);

            string key = "";

            foreach (string name in obj.TypeNames)
            {
                if (_PropertyMapping.ContainsKey(name))
                {
                    key = name;
                    break;
                }
            }

            if (key == "")
                return Input;

            foreach (string property in _PropertyMapping[key])
                if (obj.Properties[property] != null && obj.Properties[property].Value != null && !String.IsNullOrEmpty(obj.Properties[property].Value as string))
                    return obj.Properties[property].Value;

            return Input;
        }

        /// <summary>
        /// Add two parameter classes representing resolved paths.
        /// Mostly intended to converge literal and non-literal parameter options.
        /// Note: PowerShell will usually enumerate the result of this, leading to a simple object array
        /// </summary>
        /// <param name="a"></param>
        /// <param name="b"></param>
        /// <returns></returns>
        public static PathFileSystemParameterBase operator +(PathFileSystemParameterBase a, PathFileSystemParameterBase b)
        {
            // Create a new object of the first input type without any constructor logic.
            // Since all the constructors do is resolving the input and we copy the results of that, this should be safe
            PathFileSystemParameterBase newObject = (PathFileSystemParameterBase)FormatterServices.GetUninitializedObject(a.GetType());
            newObject.AddRange(a);
            foreach (object item in b)
                newObject.AddEx((string)item);
            foreach (object error in a.FailedInput)
                newObject.FailedInput.Add(error);
            foreach (object error in b.FailedInput)
                newObject.FailedInput.Add(error);

            return newObject;
        }

        /// <summary>
        /// The default string display style
        /// </summary>
        /// <returns></returns>
        public override string ToString()
        {
            return String.Join(", ", this);
        }
    }
}
