using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Runspace
{
    internal class RSPowerShellWrapper : IDisposable
    {
        internal PowerShell Pipe;
        internal IAsyncResult Status;

        internal RSPowerShellWrapper(PowerShell pipe, IAsyncResult status)
        {
            Pipe = pipe;
            Status = status;
        }

		public void Dispose()
		{
			Pipe.Dispose();
		}
    }
}
