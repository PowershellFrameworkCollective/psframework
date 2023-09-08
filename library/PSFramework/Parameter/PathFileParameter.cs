using System;
using System.Collections;
using System.Collections.Concurrent;
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
    /// Input Converter for file input
    /// </summary>
    public class PathFileParameter : PathFileSystemParameterBase
    {
        #region Constructors
        /// <summary>
        /// Convert a single path
        /// </summary>
        /// <param name="Path"></param>
        public PathFileParameter(string Path)
        {
            InputObject = Path;
            foreach (string filePath in ResolveFileSystemPath(Path, true, false, true))
                AddEx(filePath);
        }
        /// <summary>
        /// Convert any number of paths
        /// </summary>
        /// <param name="Path"></param>
        public PathFileParameter(string[] Path)
        {
            InputObject = Path;
            foreach (string entry in Path)
                foreach (string filePath in ResolveFileSystemPath(entry, true, false, true))
                    AddEx(filePath);
        }
        /// <summary>
        /// Convert a single FileInfo object
        /// </summary>
        /// <param name="File"></param>
        /// <exception cref="ArgumentException"></exception>
        public PathFileParameter(FileInfo File)
        {
            InputObject = File;
            if (!File.Exists)
                throw new ArgumentException($"File does not exist! {File.FullName}");
            AddEx(File.FullName);
        }
        /// <summary>
        /// Convert a single Uri
        /// </summary>
        /// <param name="Uri"></param>
        public PathFileParameter(Uri Uri)
            :this(Uri.OriginalString) { }
        /// <summary>
        /// Convert multiple Uris
        /// </summary>
        /// <param name="Uri"></param>
        public PathFileParameter(Uri[] Uri)
            : this(Uri.Select(o => o.OriginalString).ToArray()) { }
        /// <summary>
        /// Convert any number of FileInfo objects
        /// </summary>
        /// <param name="File"></param>
        /// <exception cref="ArgumentException"></exception>
        public PathFileParameter(FileInfo[] File)
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
        public PathFileParameter(object Input)
        {
            if (Input == null)
                throw new ArgumentException("Input must not be null");

            InputObject = Input;
            string[] paths = LanguagePrimitives.ConvertTo<string[]>(GetObject(Input));
            foreach (string entry in paths)
                foreach (string filePath in ResolveFileSystemPath(entry, true, false, true))
                    AddEx(filePath);
        }
        #endregion Constructors
    }
}