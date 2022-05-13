using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Temp
{
    /// <summary>
    /// Extensibility tool, providing logic to custom-deploy temporary items
    /// </summary>
    public class TempItemProvider
    {
        /// <summary>
        /// Name of the provider
        /// </summary>
        public string Name;

        /// <summary>
        /// Scriptblock to execute as you create the temporary item
        /// </summary>
        public ScriptBlock CreationScript;

        /// <summary>
        /// Scriptblock verifying the existence of the item
        /// </summary>
        public ScriptBlock ExistsScript;

        /// <summary>
        /// Scriptblock deleting the temporary item.
        /// </summary>
        public ScriptBlock DeleteScript;

        /// <summary>
        /// Create a new TempItemProvider
        /// </summary>
        /// <param name="Name">Name of the provider</param>
        /// <param name="CreationScript">Scriptblock to execute as you create the temporary item</param>
        /// <param name="ExistsScript">Scriptblock verifying the existence of the item</param>
        /// <param name="DeleteScript">Scriptblock deleting the temporary item.</param>
        public TempItemProvider(string Name, ScriptBlock CreationScript, ScriptBlock ExistsScript, ScriptBlock DeleteScript)
        {
            this.Name = Name;
            this.CreationScript = CreationScript;
            this.ExistsScript = ExistsScript;
            this.DeleteScript = DeleteScript;
        }
    }
}
