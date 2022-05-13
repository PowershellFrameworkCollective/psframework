using System;
using System.IO;

namespace PSFramework.Temp
{
    /// <summary>
    /// A temporary directory, that shall be deleted in due time
    /// </summary>
    public class TempItemDirectory : TempItem
    {
        /// <summary>
        /// The fact that this is a file
        /// </summary>
        public override TempItemType Type => TempItemType.Directory;

        /// <summary>
        /// Whether the directory still exists
        /// </summary>
        public override bool Exists => (new DirectoryInfo(Path)).Exists;

        /// <summary>
        /// The provider implementing this temp item
        /// </summary>
        public new string ProviderName => "Directory";

        /// <summary>
        /// The full path to the directory
        /// </summary>
        public string Path;

        /// <summary>
        /// Delete the directory and remove it from the list of temporary items
        /// </summary>
        public override void Delete()
        {
            WriteMessage($"Deleting { Module }\\{ Name }");
            if (Exists)
            {
                try { Directory.Delete(Path, true); }
                catch (Exception e)
                {
                    WriteError($"Failed to delete temp directory { Module }\\{ Name } ({ Path }): { e.Message }", e);
                    return;
                }
            }
            Parent.Items.Remove(this);
        }

        /// <summary>
        /// Create a new temporary directory object (directory itself is not created)
        /// </summary>
        /// <param name="Name">Name of the temp directory</param>
        /// <param name="Module">Name of the module owning the temp directory</param>
        /// <param name="Path">Path to the temporary directory</param>
        /// <param name="Parent">The parent container.</param>
        public TempItemDirectory(string Name, string Module, string Path, TempItemContainer Parent)
        {
            this.Name = Name;
            this.Module = Module;
            this.Path = Path;
            this.Parent = Parent;
            Parent.Items.Add(this);
        }
    }
}
