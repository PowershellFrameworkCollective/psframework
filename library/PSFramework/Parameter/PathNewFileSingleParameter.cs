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
    /// ParameterClass to map to a single file that needs not exist, but whose parent directory must.
    /// </summary>
    public class PathNewFileSingleParameter : PathFileSystemSingleParameterBase
    {
        #region Constructors
        /// <summary>
        /// Processes a single string as a single file.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathNewFileSingleParameter(string Path)
        {
            InputObject = Path;
            ApplyNew(Path);
        }

        /// <summary>
        /// Processes a single FileInfo item as a single file.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathNewFileSingleParameter(FileInfo Path) : this(Path.FullName) { InputObject = Path; }

        /// <summary>
        /// Processes a single Uri as a single file.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathNewFileSingleParameter(Uri Path) : this(Path.OriginalString) { InputObject = Path; }

        /// <summary>
        /// Processes a single object as a single file.
        /// </summary>
        /// <param name="Path">The path to process</param>
        public PathNewFileSingleParameter(object Path)
        {
            InputObject = Path;
            string actualpath;
            try { actualpath = LanguagePrimitives.ConvertTo<string>(PathFileSystemParameterBase.GetObject(Path)); }
            catch (Exception e) { throw new ArgumentException($"Failed to process {Path}! Error converting to string: {e.Message}", e); }

            ApplyNew(actualpath);
        }
        #endregion Constructors

        #region Operators
        /// <summary>
        /// Implicitly convert to string.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator string(PathNewFileSingleParameter Path)
        {
            return Path.Path;
        }

        /// <summary>
        /// Implicitly convert to FileInfo.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator FileInfo(PathNewFileSingleParameter Path)
        {
            return new FileInfo(Path.Path);
        }

        /// <summary>
        /// Implicitly convert FileInfo to PathDirectorySingleParameter.
        /// </summary>
        /// <param name="Info">The path to convert</param>
        public static implicit operator PathNewFileSingleParameter(FileInfo Info)
        {
            return new PathNewFileSingleParameter(Info);
        }

        /// <summary>
        /// Implicitly convert to FileSystemInfo.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator FileSystemInfo(PathNewFileSingleParameter Path)
        {
            return new FileInfo(Path.Path);
        }
        #endregion Operators

        internal void ApplyNew(string Path)
        {
            SessionState state = new SessionState();
            string basePath = state.Path.GetUnresolvedProviderPathFromPSPath(Path);
            string parentPath = state.Path.ParseParent(basePath, "");

            if (Directory.Exists(basePath))
                throw new ArgumentException($"Invalid input: Target path is a directory, not a file! {Path}");
            if (!File.Exists(basePath) && !Directory.Exists(parentPath))
                throw new ArgumentException($"Invalid input: Neither file nor parent folder exist! {Path}");

            this.Path = basePath;
        }
    }
}
