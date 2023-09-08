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
    /// Input converter performing path evaluation without wildcard interpretation
    /// </summary>
    public class PathLiteralParameter : PathFileSystemParameterBase
    {
        #region Constructors
        /// <summary>
        /// Convert a single path
        /// </summary>
        /// <param name="Path"></param>
        public PathLiteralParameter(string Path)
        {
            InputObject = Path;
            foreach (string filePath in ResolveFileSystemPath(Path, true, true, true, false))
                AddEx(filePath);
        }
        /// <summary>
        /// Convert any number of paths
        /// </summary>
        /// <param name="Path"></param>
        public PathLiteralParameter(string[] Path)
        {
            InputObject = Path;
            foreach (string entry in Path)
                foreach (string filePath in ResolveFileSystemPath(entry, true, true, true, false))
                    AddEx(filePath);
        }
        /// <summary>
        /// Convert a single FileInfo object
        /// </summary>
        /// <param name="File"></param>
        /// <exception cref="ArgumentException"></exception>
        public PathLiteralParameter(FileInfo File)
        {
            InputObject = File;
            if (!File.Exists)
                throw new ArgumentException($"File does not exist! {File.FullName}");
            AddEx(File.FullName);
        }
        /// <summary>
        /// Convert a single DirectoryInfo object
        /// </summary>
        /// <param name="Directory"></param>
        /// <exception cref="ArgumentException"></exception>
        public PathLiteralParameter(DirectoryInfo Directory)
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
        public PathLiteralParameter(DirectoryInfo[] Directory)
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
        /// Convert a single Uri
        /// </summary>
        /// <param name="Uri"></param>
        public PathLiteralParameter(Uri Uri)
            : this(Uri.OriginalString) { }
        /// <summary>
        /// Convert multiple Uris
        /// </summary>
        /// <param name="Uri"></param>
        public PathLiteralParameter(Uri[] Uri)
            : this(Uri.Select(o => o.OriginalString).ToArray()) { }
        /// <summary>
        /// Convert any number of FileInfo objects
        /// </summary>
        /// <param name="File"></param>
        /// <exception cref="ArgumentException"></exception>
        public PathLiteralParameter(FileInfo[] File)
        {
            InputObject = File;
            foreach (FileInfo entry in File)
            {
                if (!entry.Exists)
                    throw new ArgumentException($"File does not exist! {entry.FullName}");
                AddEx(entry.FullName);
            }
        }
        /// <summary>
        /// Convert anything else
        /// </summary>
        /// <param name="Input"></param>
        public PathLiteralParameter(object Input)
        {
            if (Input == null)
                throw new ArgumentException("Input must not be null");

            InputObject = Input;
            string[] paths = LanguagePrimitives.ConvertTo<string[]>(GetObject(Input));
            foreach (string entry in paths)
                foreach (string filePath in ResolveFileSystemPath(entry, true, true, true, false))
                    AddEx(filePath);
        }
        #endregion Constructors
    }
}
