using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Configuration
{
    /// <summary>
    /// The data types supported by the configuration system.
    /// </summary>
    public enum ConfigurationValueType
    {
        /// <summary>
        /// An unknown type, should be prevented
        /// </summary>
        Unknown,

        /// <summary>
        /// The value is as empty as the void.
        /// </summary>
        Null,

        /// <summary>
        /// The value is of a true/false kind
        /// </summary>
        Bool,

        /// <summary>
        /// The value is a regular integer
        /// </summary>
        Int,

        /// <summary>
        /// The value is a double numeric value
        /// </summary>
        Double,

        /// <summary>
        /// The value is a long type
        /// </summary>
        Long,

        /// <summary>
        /// The value is a common string
        /// </summary>
        String,

        /// <summary>
        /// The value is a regular timespan
        /// </summary>
        Timespan,

        /// <summary>
        /// The value is a plain datetime
        /// </summary>
        Datetime,

        /// <summary>
        /// The value is a fancy console color
        /// </summary>
        ConsoleColor,

        /// <summary>
        /// The value is an array full of booty
        /// </summary>
        Array,

        /// <summary>
        /// The value is something indeterminate, but possibly complex
        /// </summary>
        Object,
    }
}
