using System;

namespace PSFramework.PSFCore
{
    /// <summary>
    /// Attribute designating something as reserved as PSFramework-internal.
    /// Changes to any component marked thus is not considered a breaking change.
    /// </summary>
    [AttributeUsage(AttributeTargets.All)]
    internal class PsfInternalAttribute : Attribute
    {
        /// <summary>
        /// Allows specifying a description or comments along with the attribute.
        /// </summary>
        public string Description;
    }
}
