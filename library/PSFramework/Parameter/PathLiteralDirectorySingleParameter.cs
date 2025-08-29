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
    /// Parameter class that maps to a single directory.
    /// </summary>
    public class PathLiteralDirectorySingleParameter : PathFileSystemSingleParameterBase
    {
        #region Constructors
        /// <summary>
        /// Processes a single string as a single directory.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathLiteralDirectorySingleParameter(string Path)
        {
            InputObject = Path;
            ApplyLiteral(Path, false, true);
        }

        /// <summary>
        /// Processes a single DirectoryInfo item as a single directory.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathLiteralDirectorySingleParameter(DirectoryInfo Path) : this(Path.FullName) { InputObject = Path; }

        /// <summary>
        /// Processes a single Uri as a single directory.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathLiteralDirectorySingleParameter(Uri Path) : this(Path.OriginalString) { InputObject = Path; }

        /// <summary>
        /// Processes a single object as a single directory.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathLiteralDirectorySingleParameter(object Path)
        {
            InputObject = Path;
            string actualpath;
            try { actualpath = LanguagePrimitives.ConvertTo<string>(PathFileSystemParameterBase.GetObject(Path)); }
            catch (Exception e) { throw new ArgumentException($"Failed to process {Path}! Error converting to string: {e.Message}", e); }

            ApplyLiteral(actualpath, false, true);
        }
        #endregion Constructors

        #region Operators
        /// <summary>
        /// Implicitly convert to string.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator string(PathLiteralDirectorySingleParameter Path)
        {
            return Path.Path;
        }

        /// <summary>
        /// Implicitly convert to DirectoryInfo.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator DirectoryInfo(PathLiteralDirectorySingleParameter Path)
        {
            return new DirectoryInfo(Path.Path);
        }

        /// <summary>
        /// Implicitly convert DirectoryInfo to PathLiteralDirectorySingleParameter.
        /// </summary>
        /// <param name="Info">The path to convert</param>
        public static implicit operator PathLiteralDirectorySingleParameter(DirectoryInfo Info)
        {
            return new PathLiteralDirectorySingleParameter(Info);
        }

        /// <summary>
        /// Implicitly convert to FileSystemInfo.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator FileSystemInfo(PathLiteralDirectorySingleParameter Path)
        {
            return new DirectoryInfo(Path.Path);
        }
        #endregion Operators
    }
}
