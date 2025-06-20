using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Parameter
{
    /// <summary>
    /// Parameterclass accepting/resolving to a single, fully-resolved path to a file.
    /// </summary>
    public class PathFileSingleParameter : ParameterClass
    {
        /// <summary>
        /// The fully-resolved path
        /// </summary>
        [ParameterContract(ParameterContractType.Field, ParameterContractBehavior.Mandatory)]
        public string Path;

        #region Constructors
        /// <summary>
        /// Processes a single string as a single file.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathFileSingleParameter(string Path) {
            InputObject = Path;
            Apply(Path);
        }

        /// <summary>
        /// Processes a single FileInfo item as a single file.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathFileSingleParameter(FileInfo Path) :this(Path.FullName) { InputObject = Path; }

        /// <summary>
        /// Processes a single Uri as a single file.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathFileSingleParameter(Uri Path) :this(Path.OriginalString) { InputObject = Path; }

        /// <summary>
        /// Processes a single object as a single file.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathFileSingleParameter(object Path)
        {
            InputObject = Path;
            string actualpath;
            try { actualpath = LanguagePrimitives.ConvertTo<string>(PathFileSystemParameterBase.GetObject(Path)); }
            catch (Exception e) { throw new ArgumentException($"Failed to process {Path}! Error converting to string: {e.Message}", e); }

            Apply(actualpath);
        }
        #endregion Constructors

        #region Utilities
        internal void Apply(string Path)
        {
            IEnumerable<string> resolved;
            try { resolved = (new SessionState()).Path.GetResolvedPSPathFromPSPath(Path).Where(o => o.Provider.Name == "FileSystem").Select(o => o.ProviderPath); }
            catch (Exception e) { throw new ArgumentException($"Unable to resolve path: {0}", e); }

            if (resolved.Count() > 1)
                throw new InvalidDataException($"Accepting only a single file. Path {Path} resolves to {resolved.Count()} items!");
            if (resolved.Count() == 0)
                throw new FileNotFoundException($"Unable to resolve to file, item not found: {Path}");

            if (!File.Exists(resolved.First()))
                throw new FileNotFoundException($"Path {Path} is not a file! (Resolved to {resolved.First()})");

            this.Path = resolved.First();
        }
        #endregion Utilities

        /// <summary>
        /// Default text representation of the PathFileSingle type.
        /// </summary>
        /// <returns>Its path.</returns>
        public override string ToString()
        {
            return Path;
        }

        #region Implicit Casts
        /// <summary>
        /// Implicitly convert to string.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator string(PathFileSingleParameter Path)
        {
            return Path.Path;
        }
        /// <summary>
        /// Implicitly convert to FileInfo.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator FileInfo(PathFileSingleParameter Path)
        {
            return new FileInfo(Path.Path);
        }
        /// <summary>
        /// Implicitly convert FileInfo to PathFileSingle.
        /// </summary>
        /// <param name="Info">The path to convert</param>

        public static implicit operator PathFileSingleParameter(FileInfo Info)
        {
            return new PathFileSingleParameter(Info);
        }
        /// <summary>
        /// Implicitly convert to FileSystemInfo.
        /// </summary>
        /// <param name="Path">The path to convert</param>

        public static implicit operator FileSystemInfo(PathFileSingleParameter Path)
        {
            return new FileInfo(Path.Path);
        }
        #endregion Implicit Casts
    }
}
