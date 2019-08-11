using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Management.Automation;

namespace PSFramework.Meta
{
    internal class PSTraceSource
    {
        internal static PSArgumentException NewArgumentException(string paramName)
        {
            if (string.IsNullOrEmpty(paramName))
            {
                throw new ArgumentNullException("paramName");
            }

            return new PSArgumentException(paramName, paramName);
        }
    }
}
