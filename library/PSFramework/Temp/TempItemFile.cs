using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Temp
{
    /// <summary>
    /// A temporary file, that shall be deleted in due time
    /// </summary>
    public  class TempItemFile : TempItem
    {
        /// <summary>
        /// The fact that this is a file
        /// </summary>
        public override TempItemType Type => TempItemType.File;
        
        /// <summary>
        /// Whether the file still exists
        /// </summary>
        public override bool Exists => (new FileInfo(Path)).Exists;

        /// <summary>
        /// The full path to the file
        /// </summary>
        public string Path;

        /// <summary>
        /// Delete the file and remove it from the list of temporary items
        /// </summary>
        public override void Delete()
        {
            WriteMessage($"Deleting { Module }\\{ Name }");
            if (Exists)
            {
                try { File.Delete(Path); }
                catch (Exception e)
                {
                    WriteError($"Failed to delete temp file { Module }\\{ Name } ({ Path }): { e.Message }", e);
                    return;
                }
            }
            Parent.Items.Remove(this);
        }

        /// <summary>
        /// Create a new temporary file object (file itself is not created)
        /// </summary>
        /// <param name="Name">Name of the temp file</param>
        /// <param name="Module">Name of the module owning the temp file</param>
        /// <param name="Path">Path to the temporary file</param>
        /// <param name="Parent">The parent container.</param>
        public TempItemFile(string Name, string Module, string Path, TempItemContainer Parent)
        {
            this.Name = Name;
            this.Module = Module;
            this.Path = Path;
            this.Parent = Parent;
            Parent.Items.Add(this);
        }
    }
}
