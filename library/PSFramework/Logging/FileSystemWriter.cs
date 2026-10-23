using PSFramework.Message;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Threading.Tasks;

namespace PSFramework.Logging
{
    /// <summary>
    /// Helper class used by the FileSystem logging provider to write data at max performance
    /// </summary>
    public class FileSystemWriter
    {
        // Converter Code that generates CSV without headers
        private static string CodeNoHeader = "Microsoft.PowerShell.Utility\\ConvertTo-Csv -NoTypeInformation -NoHeader";
        // Converter Code that generates CSV WITH headers
        private static string CodeHeader = "Microsoft.PowerShell.Utility\\ConvertTo-Csv -NoTypeInformation";

        /// <summary>
        /// The Path to where is written. Changing this recalculates converters and establishes a filestream
        /// </summary>
        public string Path
        {
            get => _Path;
            set
            {
                if (_Path == value)
                    return;

                // Close out previous writer and converter
                End();

                if (!LogHost.FileSystemModernLog || System.IO.File.Exists(value))
                    _Converter = ScriptBlock.Create(CodeNoHeader).GetSteppablePipeline();
                else
                    _Converter = ScriptBlock.Create(CodeHeader).GetSteppablePipeline();
                _Converter.Begin(true);

                _Writer = new StreamWriter(value, true, new UTF8Encoding(true));
                _Writer.AutoFlush = true;

                _Path = value;
                _Info = new FileInfo(value);
            }
        }
        private string _Path;

        /// <summary>
        /// Size of the logfile.
        /// Defaults to 0 if file not present.
        /// Used to determine file-split based on size.
        /// </summary>
        public long Size
        {
            get
            {
                _Info.Refresh();
                if (!_Info.Exists)
                    return 0;
                return _Info.Length;
            }
        }

        private SteppablePipeline _Converter;

        private StreamWriter _Writer;

        private FileInfo _Info;

        /// <summary>
        /// Writes a line to the logfile
        /// </summary>
        /// <param name="Line">The line of text to write</param>
        public void WriteLine(string Line)
        {
            _Writer.WriteLine(Line);
        }

        /// <summary>
        /// Writes an object to the logfile.
        /// Will convert it to csv first.
        /// </summary>
        /// <param name="Item">The item to write</param>
        public void WriteObject(PSObject Item)
        {
            foreach (object item in _Converter.Process(Item))
                _Writer.WriteLine(item.ToString());
        }

        /// <summary>
        /// Clean up both converter and writer
        /// </summary>
        public void End()
        {
            if (null != _Converter)
            {
                _Converter.End();
                _Converter = null;
            }

            if (null != _Writer)
            {
                _Writer.Dispose();
                _Writer = null;
            }
        }
    }
}
