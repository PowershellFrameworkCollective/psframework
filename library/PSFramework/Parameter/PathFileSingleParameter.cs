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
    public class PathFileSingleParameter : PathFileSystemSingleParameterBase
    {
        #region Constructors
        /// <summary>
        /// Processes a single string as a single file.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathFileSingleParameter(string Path) {
            InputObject = Path;
            Apply(Path, true, false);
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

            Apply(actualpath, true, false);
        }
        #endregion Constructors

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
