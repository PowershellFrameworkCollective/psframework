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
    /// Parameter Class that maps to a single file or directory, without resolving wildcards.
    /// </summary>
    public class PathLiteralSingleParameter : PathFileSystemSingleParameterBase
    {
        #region Constructors
        /// <summary>
        /// Processes a single string as a single directory or file.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathLiteralSingleParameter(string Path)
        {
            InputObject = Path;
            ApplyLiteral(Path, true, true);
        }

        /// <summary>
        /// Processes a single DirectoryInfo item as a single directory.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathLiteralSingleParameter(DirectoryInfo Path) : this(Path.FullName) { InputObject = Path; }

        /// <summary>
        /// Processes a single FileInfo item as a single file.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathLiteralSingleParameter(FileInfo Path) : this(Path.FullName) { InputObject = Path; }

        /// <summary>
        /// Processes a single Uri as a single directory or file.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathLiteralSingleParameter(Uri Path) : this(Path.OriginalString) { InputObject = Path; }

        /// <summary>
        /// Processes a single object as a single directory or file.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathLiteralSingleParameter(object Path)
        {
            InputObject = Path;
            string actualpath;
            try { actualpath = LanguagePrimitives.ConvertTo<string>(PathFileSystemParameterBase.GetObject(Path)); }
            catch (Exception e) { throw new ArgumentException($"Failed to process {Path}! Error converting to string: {e.Message}", e); }

            ApplyLiteral(actualpath, true, true);
        }
        #endregion Constructors

        #region Operators
        /// <summary>
        /// Implicitly convert to string.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator string(PathLiteralSingleParameter Path)
        {
            return Path.Path;
        }

        /// <summary>
        /// Implicitly convert to DirectoryInfo.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator DirectoryInfo(PathLiteralSingleParameter Path)
        {
            return new DirectoryInfo(Path.Path);
        }

        /// <summary>
        /// Implicitly convert to DirectoryInfo.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator FileInfo(PathLiteralSingleParameter Path)
        {
            return new FileInfo(Path.Path);
        }

        /// <summary>
        /// Implicitly convert DirectoryInfo to PathDirectorySingleParameter.
        /// </summary>
        /// <param name="Info">The path to convert</param>
        public static implicit operator PathLiteralSingleParameter(DirectoryInfo Info)
        {
            return new PathLiteralSingleParameter(Info);
        }

        /// <summary>
        /// Implicitly convert FileInfo to PathDirectorySingleParameter.
        /// </summary>
        /// <param name="Info">The path to convert</param>
        public static implicit operator PathLiteralSingleParameter(FileInfo Info)
        {
            return new PathLiteralSingleParameter(Info);
        }

        /// <summary>
        /// Implicitly convert to FileSystemInfo.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator FileSystemInfo(PathLiteralSingleParameter Path)
        {
            if (File.Exists(Path.Path))
                return new FileInfo(Path.Path);
            return new DirectoryInfo(Path.Path);
        }
        #endregion Operators
    }
}
