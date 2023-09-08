using System;
using System.IO;
using System.Linq;
using System.Management.Automation;

namespace PSFramework.Parameter
{
    /// <summary>
    /// Interpret input values as directory paths
    /// </summary>
    public class PathDirectoryParameter : PathFileSystemParameterBase
    {
        #region Constructors
        /// <summary>
        /// Convert a single path
        /// </summary>
        /// <param name="Path"></param>
        public PathDirectoryParameter(string Path)
        {
            InputObject = Path;
            foreach (string directoryPath in ResolveFileSystemPath(Path, false, true, true))
                AddEx(directoryPath);
        }
        /// <summary>
        /// Convert any number of paths
        /// </summary>
        /// <param name="Path"></param>
        public PathDirectoryParameter(string[] Path)
        {
            InputObject = Path;
            foreach (string entry in Path)
                foreach (string directoryPath in ResolveFileSystemPath(entry, false, true, true))
                    AddEx(directoryPath);
        }
        /// <summary>
        /// Convert a single Uri
        /// </summary>
        /// <param name="Uri"></param>
        public PathDirectoryParameter(Uri Uri)
            : this(Uri.OriginalString) { }
        /// <summary>
        /// Convert multiple Uris
        /// </summary>
        /// <param name="Uri"></param>
        public PathDirectoryParameter(Uri[] Uri)
            : this(Uri.Select(o => o.OriginalString).ToArray()) { }
        /// <summary>
        /// Convert a single DirectoryInfo object
        /// </summary>
        /// <param name="Directory"></param>
        /// <exception cref="ArgumentException"></exception>
        public PathDirectoryParameter(DirectoryInfo Directory)
        {
            InputObject = Directory;
            if (!Directory.Exists)
                throw new ArgumentException($"Directory does not exist! {Directory.FullName}");
            AddEx(Directory.FullName);
        }
        /// <summary>
        /// Convert any number of DirectoryInfo objects
        /// </summary>
        /// <param name="Directory"></param>
        /// <exception cref="ArgumentException"></exception>
        public PathDirectoryParameter(DirectoryInfo[] Directory)
        {
            InputObject = Directory;
            foreach (DirectoryInfo entry in Directory)
            {
                if (!entry.Exists)
                    throw new ArgumentException($"Directory does not exist! {entry.FullName}");
                AddEx(entry.FullName);
            }
        }
        /// <summary>
        /// Convert anything else
        /// </summary>
        /// <param name="Input"></param>
        public PathDirectoryParameter(object Input)
        {
            if (Input == null)
                throw new ArgumentException("Input must not be null");

            InputObject = Input;
            string[] paths = LanguagePrimitives.ConvertTo<string[]>(GetObject(Input));
            foreach (string entry in paths)
                foreach (string directoryPath in ResolveFileSystemPath(entry, false, true, true))
                    AddEx(directoryPath);
        }
        #endregion Constructors
    }
}