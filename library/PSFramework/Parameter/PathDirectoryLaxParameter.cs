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
    /// Interpret input values as directory paths, silently ignoring bad input
    /// </summary>
    public class PathDirectoryLaxParameter : PathFileSystemParameterBase
    {
        #region Constructors
        /// <summary>
        /// Convert a single path
        /// </summary>
        /// <param name="Path"></param>
        public PathDirectoryLaxParameter(string Path)
        {
            InputObject = Path;
            foreach (string directoryPath in ResolveFileSystemPath(Path, false, true, false))
                AddEx(directoryPath);
        }
        /// <summary>
        /// Convert any number of paths
        /// </summary>
        /// <param name="Path"></param>
        public PathDirectoryLaxParameter(string[] Path)
        {
            InputObject = Path;
            foreach (string entry in Path)
                foreach (string directoryPath in ResolveFileSystemPath(entry, false, true, false))
                    AddEx(directoryPath);
        }
        /// <summary>
        /// Convert a single Uri
        /// </summary>
        /// <param name="Uri"></param>
        public PathDirectoryLaxParameter(Uri Uri)
            : this(Uri.OriginalString) { }
        /// <summary>
        /// Convert multiple Uris
        /// </summary>
        /// <param name="Uri"></param>
        public PathDirectoryLaxParameter(Uri[] Uri)
            : this(Uri.Select(o => o.OriginalString).ToArray()) { }
        /// <summary>
        /// Convert a single DirectoryInfo object
        /// </summary>
        /// <param name="Directory"></param>
        /// <exception cref="ArgumentException"></exception>
        public PathDirectoryLaxParameter(DirectoryInfo Directory)
        {
            InputObject = Directory;
            if (!Directory.Exists)
                FailedInput.Add(Directory);
            else
                AddEx(Directory.FullName);
        }
        /// <summary>
        /// Convert any number of DirectoryInfo objects
        /// </summary>
        /// <param name="Directory"></param>
        /// <exception cref="ArgumentException"></exception>
        public PathDirectoryLaxParameter(DirectoryInfo[] Directory)
        {
            InputObject = Directory;
            foreach (DirectoryInfo entry in Directory)
            {
                if (!entry.Exists)
                    FailedInput.Add(entry);
                else
                    AddEx(entry.FullName);
            }
        }
        /// <summary>
        /// Convert anything else
        /// </summary>
        /// <param name="Input"></param>
        public PathDirectoryLaxParameter(object Input)
        {
            if (Input == null)
                return;

            InputObject = Input;
            string[] paths = LanguagePrimitives.ConvertTo<string[]>(GetObject(Input));
            foreach (string entry in paths)
                foreach (string directoryPath in ResolveFileSystemPath(entry, false, true, false))
                    AddEx(directoryPath);
        }
        #endregion Constructors
    }
}
