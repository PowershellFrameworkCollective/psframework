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
    /// Parameterclass that accepts a single directory
    /// </summary>
    public class PathDirectorySingleParameter : PathFileSystemSingleParameterBase
    {
        #region Constructors
        /// <summary>
        /// Processes a single string as a single directory.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathDirectorySingleParameter(string Path)
        {
            InputObject = Path;
            Apply(Path, true, false);
        }

        /// <summary>
        /// Processes a single DirectoryInfo item as a single directory.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathDirectorySingleParameter(DirectoryInfo Path) : this(Path.FullName) { InputObject = Path; }

        /// <summary>
        /// Processes a single Uri as a single directory.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathDirectorySingleParameter(Uri Path) : this(Path.OriginalString) { InputObject = Path; }

        /// <summary>
        /// Processes a single object as a single directory.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathDirectorySingleParameter(object Path)
        {
            InputObject = Path;
            string actualpath;
            try { actualpath = LanguagePrimitives.ConvertTo<string>(PathFileSystemParameterBase.GetObject(Path)); }
            catch (Exception e) { throw new ArgumentException($"Failed to process {Path}! Error converting to string: {e.Message}", e); }

            Apply(actualpath, true, false);
        }
        #endregion Constructors

        #region Operators
        /// <summary>
        /// Implicitly convert to string.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator string(PathDirectorySingleParameter Path)
        {
            return Path.Path;
        }
        /// <summary>
        /// Implicitly convert to DirectoryInfo.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator DirectoryInfo(PathDirectorySingleParameter Path)
        {
            return new DirectoryInfo(Path.Path);
        }
        /// <summary>
        /// Implicitly convert DirectoryInfo to PathDirectorySingleParameter.
        /// </summary>
        /// <param name="Info">The path to convert</param>

        public static implicit operator PathDirectorySingleParameter(DirectoryInfo Info)
        {
            return new PathDirectorySingleParameter(Info);
        }
        /// <summary>
        /// Implicitly convert to FileSystemInfo.
        /// </summary>
        /// <param name="Path">The path to convert</param>

        public static implicit operator FileSystemInfo(PathDirectorySingleParameter Path)
        {
            return new DirectoryInfo(Path.Path);
        }
        #endregion Operators
    }
}
