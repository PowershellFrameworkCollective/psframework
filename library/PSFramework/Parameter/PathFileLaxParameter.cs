using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Parameter
{
    /// <summary>
    /// Parameter class that will not throw on bad or empty input and will instead just return empty paths
    /// </summary>
    public class PathFileLaxParameter : PathFileSystemParameterBase
    {
        #region Constructors
        /// <summary>
        /// Convert a single path
        /// </summary>
        /// <param name="Path"></param>
        public PathFileLaxParameter(string Path)
        {
            InputObject = Path;
            foreach (string filePath in ResolveFileSystemPath(Path, true, false, false))
                AddEx(filePath);
        }
        /// <summary>
        /// Convert any number of paths
        /// </summary>
        /// <param name="Path"></param>
        public PathFileLaxParameter(string[] Path)
        {
            InputObject = Path;
            foreach (string entry in Path)
                foreach (string filePath in ResolveFileSystemPath(entry, true, false, false))
                    AddEx(filePath);
        }
        /// <summary>
        /// Convert a single Uri
        /// </summary>
        /// <param name="Uri"></param>
        public PathFileLaxParameter(Uri Uri)
            : this(Uri.OriginalString) { }
        /// <summary>
        /// Convert multiple Uris
        /// </summary>
        /// <param name="Uri"></param>
        public PathFileLaxParameter(Uri[] Uri)
            : this(Uri.Select(o => o.OriginalString).ToArray()) { }
        /// <summary>
        /// Convert a single FileInfo object
        /// </summary>
        /// <param name="File"></param>
        /// <exception cref="ArgumentException"></exception>
        public PathFileLaxParameter(FileInfo File)
        {
            InputObject = File;
            if (!File.Exists)
                FailedInput.Add(File);
            else
                AddEx(File.FullName);
        }
        /// <summary>
        /// Convert any number of FileInfo objects
        /// </summary>
        /// <param name="File"></param>
        /// <exception cref="ArgumentException"></exception>
        public PathFileLaxParameter(FileInfo[] File)
        {
            InputObject = File;
            foreach (FileInfo entry in File)
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
        public PathFileLaxParameter(object Input)
        {
            if (Input == null)
                return;

            InputObject = Input;
            string[] paths = LanguagePrimitives.ConvertTo<string[]>(GetObject(Input));
            foreach (string entry in paths)
                foreach (string filePath in ResolveFileSystemPath(entry, true, false, false))
                    AddEx(filePath);
        }
        #endregion Constructors
    }
}