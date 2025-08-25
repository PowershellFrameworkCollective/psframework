using PSFramework.Utility;
using System;
using System.Collections.Generic;
using System.Diagnostics.Eventing.Reader;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Parameter
{
    /// <summary>
    /// Base class for parameter classes mapping to a single filesystem item
    /// </summary>
    [ParameterClass()]
    public abstract class PathFileSystemSingleParameterBase : ParameterClass
    {
        /// <summary>
        /// The path resolved
        /// </summary>
        [ParameterContract(ParameterContractType.Field, ParameterContractBehavior.Mandatory)]
        public string Path;

        /// <summary>
        /// Default text representation of the PathFileSingle type.
        /// </summary>
        /// <returns>Its path.</returns>
        public override string ToString()
        {
            return Path;
        }

        /// <summary>
        /// Resolve the path provided and ensure it exists and is of the proper type!
        /// </summary>
        /// <param name="Path">The path to resolve</param>
        /// <param name="MayBeFile">Whether it may be a file</param>
        /// <param name="MayBeDirectory">Whether it may be a directory</param>
        /// <exception cref="ArgumentException">When the path provided cannot be resolved at all.</exception>
        /// <exception cref="InvalidDataException">When the path provided resolves to multiple items.</exception>
        /// <exception cref="FileNotFoundException">When the path should resolve to a file, but is not a file.</exception>
        /// <exception cref="DirectoryNotFoundException">When the path should resolve to a directory, but is not a directory.</exception>
        internal void Apply(string Path, bool MayBeFile, bool MayBeDirectory)
        {
            IEnumerable<string> resolved;
            try { resolved = (new SessionState()).Path.GetResolvedPSPathFromPSPath(Path).Where(o => o.Provider.Name == "FileSystem").Select(o => o.ProviderPath); }
            catch (Exception e) { throw new ArgumentException($"Unable to resolve filesystem path: {Path}", e); }

            if (resolved.Count() > 1)
                throw new InvalidDataException($"Accepting only a single file. Path {Path} resolves to {resolved.Count()} items!");
            if (resolved.Count() == 0)
                throw new FileNotFoundException($"Unable to resolve to file, item not found: {Path}");

            if (MayBeFile && !MayBeDirectory && !File.Exists(resolved.First()))
                throw new FileNotFoundException($"Path {Path} is not a file! (Resolved to {resolved.First()})");
            if (!MayBeFile && MayBeDirectory && !Directory.Exists(resolved.First()))
                throw new DirectoryNotFoundException($"Path {Path} is not a directory! (Resolved to {resolved.First()})");

            this.Path = resolved.First();
        }

        /// <summary>
        /// Verify the specified path exists, process relative paths, but do not apply wildcards.
        /// </summary>
        /// <param name="Path">The path to process</param>
        /// <param name="MayBeFile">Whether the path may point to a file</param>
        /// <param name="MayBeDirectory">Whether the path may point to a directory</param>
        /// <exception cref="ItemNotFoundException">Thrown if the item does not exist at all</exception>
        /// <exception cref="FileNotFoundException">When the path should resolve to a file, but is not a file.</exception>
        /// <exception cref="DirectoryNotFoundException">When the path should resolve to a directory, but is not a directory.</exception>
        internal void ApplyLiteral(string Path, bool MayBeFile, bool MayBeDirectory)
        {
            string tempPath = UtilityHost.JoinPath((new SessionState()).Path.CurrentFileSystemLocation.ProviderPath, Path);

            if (!File.Exists(tempPath) && !Directory.Exists(tempPath))
                throw new ItemNotFoundException($"Unable to resolve filesystem path: {Path} (Resolved to {tempPath})");

            if (MayBeFile && !MayBeDirectory && !File.Exists(tempPath))
                throw new FileNotFoundException($"Path {Path} is not a file! (Resolved to {tempPath})");
            if (!MayBeFile && MayBeDirectory && !Directory.Exists(tempPath))
                throw new DirectoryNotFoundException($"Path {Path} is not a directory! (Resolved to {tempPath})");

            this.Path = tempPath;
        }

        /// <summary>
        /// Implicitly convert to string.
        /// </summary>
        /// <param name="Path">The path to convert</param>
        public static implicit operator string(PathFileSystemSingleParameterBase Path)
        {
            return Path.Path;
        }
    }
}
