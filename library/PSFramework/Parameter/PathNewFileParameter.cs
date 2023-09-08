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
    /// Parameter class, converting input into the path to a file, where either the file or at least its parent folder already exist.
    /// </summary>
    public class PathNewFileParameter : PathFileSystemParameterBase
    {
        #region Constructors
        /// <summary>
        /// Convert a single path
        /// </summary>
        /// <param name="Path"></param>
        public PathNewFileParameter(string Path)
        {
            InputObject = Path;
            foreach (string filePath in ResolveFileSystemPath(Path))
                AddEx(filePath);
        }
        /// <summary>
        /// Convert any number of paths
        /// </summary>
        /// <param name="Path"></param>
        public PathNewFileParameter(string[] Path)
        {
            InputObject = Path;
            foreach (string entry in Path)
                foreach (string filePath in ResolveFileSystemPath(entry))
                    AddEx(filePath);
        }
        /// <summary>
        /// Convert a single FileInfo object
        /// </summary>
        /// <param name="File"></param>
        /// <exception cref="ArgumentException"></exception>
        public PathNewFileParameter(FileInfo File)
        {
            InputObject = File;
            if (!File.Exists && !File.Directory.Exists)
                throw new ArgumentException($"Neither File nor parent Folder exist! {File.FullName}");
            AddEx(File.FullName);
        }
        /// <summary>
        /// Convert any number of FileInfo objects
        /// </summary>
        /// <param name="File"></param>
        /// <exception cref="ArgumentException"></exception>
        public PathNewFileParameter(FileInfo[] File)
        {
            InputObject = File;
            foreach (FileInfo entry in File)
            {
                if (!entry.Exists && !entry.Directory.Exists)
                    throw new ArgumentException($"Neither File nor parent Folder exist! {entry.FullName}");
                AddEx(entry.FullName);
            }
        }
        /// <summary>
        /// Convert a single Uri
        /// </summary>
        /// <param name="Uri"></param>
        public PathNewFileParameter(Uri Uri)
            : this(Uri.OriginalString) { }
        /// <summary>
        /// Convert multiple Uris
        /// </summary>
        /// <param name="Uri"></param>
        public PathNewFileParameter(Uri[] Uri)
            : this(Uri.Select(o => o.OriginalString).ToArray()) { }
        /// <summary>
        /// Convert anything else
        /// </summary>
        /// <param name="Input"></param>
        public PathNewFileParameter(object Input)
        {
            if (Input == null)
                throw new ArgumentException("Input must not be null");

            InputObject = Input;
            string[] paths = LanguagePrimitives.ConvertTo<string[]>(GetObject(Input));
            foreach (string entry in paths)
                foreach (string filePath in ResolveFileSystemPath(entry))
                    AddEx(filePath);
        }
        #endregion Constructors

        internal List<string> ResolveFileSystemPath(string Path)
        {
            List<string> paths = new List<string>();

            SessionState state = new SessionState();
            string basePath = state.Path.GetUnresolvedProviderPathFromPSPath(Path);
            string parentPath = state.Path.ParseParent(basePath, "");

            if (Directory.Exists(basePath))
                throw new ArgumentException($"Invalid input: Target path is a directory, not a file! {Path}");
            if (!File.Exists(basePath) && !Directory.Exists(parentPath))
                throw new ArgumentException($"Invalid input: Neither file nor parent folder exist! {Path}");
            paths.Add(basePath);
            return paths;
        }
    }
}
