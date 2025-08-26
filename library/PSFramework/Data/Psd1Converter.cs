using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Data
{
    /// <summary>
    /// The PSD1 conversion runtime object.
    /// Use this to transport any settings conversion plugins require.
    /// </summary>
    public class Psd1Converter
    {
        /// <summary>
        /// The reference to the PowerShell command running this conversion.
        /// Can be used to directly interact with the current runtime, send messages or throw errors.
        /// May be null.
        /// </summary>
        public Cmdlet Cmdlet;

        /// <summary>
        /// How deeply nested are we willing to delve into sub-properties?
        /// By default, this is only respected for PSObjects or Dictionaries.
        /// </summary>
        public int MaxDepth = -1;

        /// <summary>
        /// Extra configuration settings.
        /// This will be ignored by the default, builtin converters, but external ones may use this to transport and implement settings.
        /// </summary>
        public Hashtable Config = new Hashtable(StringComparer.OrdinalIgnoreCase);

        /// <summary>
        /// Convert some object to PSD1
        /// </summary>
        /// <param name="Value">The object to convert to PSD1</param>
        /// <returns>A PSD1-string</returns>
        public string Convert(object Value)
        {
            return DataHost.Convert(Value, null, 0, this);
        }

        /// <summary>
        /// Send a message (maybe)
        /// </summary>
        /// <param name="Message"></param>
        public void WriteVerbose(string Message)
        {
            if (Cmdlet != null)
            {
                Cmdlet.WriteVerbose(Message);
                return;
            }

            using (PowerShell runtime = PowerShell.Create(RunspaceMode.CurrentRunspace))
            {
                runtime.AddCommand("Microsoft.PowerShell.Utility\\Write-Verbose").AddArgument(Message).Invoke();
            }
        }
    }
}
