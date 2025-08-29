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
    /// Parameter Class that maps to a single file without processing wildcards
    /// </summary>
    public class PathLiteralFileSingleParameter : PathFileSystemSingleParameterBase
    {
        #region Constructors
        /// <summary>
        /// Processes a single string as a single file.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathLiteralFileSingleParameter(string Path)
        {
            InputObject = Path;
            ApplyLiteral(Path, true, false);
        }

        /// <summary>
        /// Processes a single FileInfo item as a single file.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathLiteralFileSingleParameter(FileInfo Path) : this(Path.FullName) { InputObject = Path; }

        /// <summary>
        /// Processes a single Uri as a single file.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathLiteralFileSingleParameter(Uri Path) : this(Path.OriginalString) { InputObject = Path; }

        /// <summary>
        /// Processes a single object as a single file.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathLiteralFileSingleParameter(object Path)
        {
            InputObject = Path;
            string actualpath;
            try { actualpath = LanguagePrimitives.ConvertTo<string>(PathFileSystemParameterBase.GetObject(Path)); }
            catch (Exception e) { throw new ArgumentException($"Failed to process {Path}! Error converting to string: {e.Message}", e); }

            ApplyLiteral(actualpath, true, false);
        }
        #endregion Constructors

        #region Operators
        /// <summary>
        /// Implicitly convert to string.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator string(PathLiteralFileSingleParameter Path)
        {
            return Path.Path;
        }

        /// <summary>
        /// Implicitly convert to FileInfo.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator FileInfo(PathLiteralFileSingleParameter Path)
        {
            return new FileInfo(Path.Path);
        }

        /// <summary>
        /// Implicitly convert FileInfo to PathLiteralFileSingleParameter.
        /// </summary>
        /// <param name="Info">The path to convert</param>
        public static implicit operator PathLiteralFileSingleParameter(FileInfo Info)
        {
            return new PathLiteralFileSingleParameter(Info);
        }

        /// <summary>
        /// Implicitly convert to FileSystemInfo.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator FileSystemInfo(PathLiteralFileSingleParameter Path)
        {
            return new FileInfo(Path.Path);
        }
        #endregion Operators
    }
}
