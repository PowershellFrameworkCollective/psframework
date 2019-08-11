using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Validation
{
    /// <summary>
    /// The preference on how to deal with no legal values being returned. Used by PsfValidateSet
    /// </summary>
    public enum NoResultsActionPreference
    {
        /// <summary>
        /// Allow to continue
        /// </summary>
        Continue,

        /// <summary>
        /// Fail in fire and blood
        /// </summary>
        Error
    }
}
