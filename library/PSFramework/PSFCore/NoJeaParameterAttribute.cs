using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.PSFCore
{
    /// <summary>
    /// The thus tagged parameter is not safe to publish with JEA
    /// </summary>
    [AttributeUsage(AttributeTargets.All)]
    public class NoJeaParameterAttribute : Attribute
    {
        
    }
}
