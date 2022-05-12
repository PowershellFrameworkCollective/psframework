using System;
using System.Collections;
using System.Management.Automation;

namespace PSFramework.Temp
{
    /// <summary>
    /// A generic temporary item. Implementation logic provided by temporary item providers.
    /// </summary>
    public class TempItemGeneric : TempItem
    {
        /// <summary>
        /// This is a generic one. Yay.
        /// </summary>
        public override TempItemType Type => TempItemType.Generic;

        /// <summary>
        /// Whether the temp item even exists.
        /// </summary>
        public override bool Exists => LanguagePrimitives.ConvertTo<bool>(ExistsScript.Invoke(Data, CreationData));

        /// <summary>
        /// The name of the provider implementing this
        /// </summary>
        public string ProviderName;

        /// <summary>
        /// Scriptblock verifying the existence of the item
        /// </summary>
        public ScriptBlock ExistsScript;

        /// <summary>
        /// Scriptblock deleting the temporary item.
        /// </summary>
        public ScriptBlock DeleteScript;

        /// <summary>
        /// Data that differentiates this item from others using the same provider
        /// </summary>
        public Hashtable Data;

        /// <summary>
        /// Data that was returned when running the creation scriptblock
        /// </summary>
        public object CreationData;

        /// <summary>
        /// Kill it with fire.
        /// </summary>
        public override void Delete()
        {
            WriteMessage($"Deleting { Module }\\{ Name }");
            if (Exists)
            {
                try { DeleteScript.Invoke(Data, CreationData); }
                catch (Exception e)
                {
                    WriteError($"Failed to delete temp item { Module }\\{ Name } : { e.Message }", e);
                    return;
                }
            }
            Parent.Items.Remove(this);
        }

        /// <summary>
        /// String representation of this object
        /// </summary>
        /// <returns>some text</returns>
        public override string ToString()
        {
            return $"{ProviderName}: {Module}>{Name}";
        }

        /// <summary>
        /// Creates a generic temporary item
        /// </summary>
        /// <param name="Name">Name of the temp item</param>
        /// <param name="Module">Name of the module owning the temp item</param>
        /// <param name="ProviderName">Name of the provider offering the implementation logic of this item</param>
        /// <param name="Data">Data defining this temp item</param>
        /// <param name="Parent">The parent container of this item</param>
        /// <param name="CreationData">Data that was returned when running the creation scriptblock</param>
        public TempItemGeneric(string Name, string Module, string ProviderName, Hashtable Data, TempItemContainer Parent, object CreationData)
        {
            this.Name = Name;
            this.Module = Module;
            this.ProviderName = ProviderName;
            this.Data = Data;
            this.Parent = Parent;
            this.CreationData = CreationData;

            if (Parent != null && Parent.Providers.ContainsKey(ProviderName))
            {
                TempItemProvider provider = Parent.Providers[ProviderName];
                ExistsScript = provider.ExistsScript;
                DeleteScript = provider.DeleteScript;
            }
        }
    }
}