using System;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

namespace PSFramework.Logging
{
    /// <summary>
    /// Helper class to properly format logging messages for the TXT-Variant of the logfile provider
    /// </summary>
    public class TxtBuilder
    {
        /// <summary>
        /// The text pattern provided by the user, describing the way the logfile is supposed to look.
        /// </summary>
        public string Text { get; private set; }

        /// <summary>
        /// The properties that exist within the text pattern. Used to optimize the content replacement process.
        /// </summary>
        private List<string> Properties = new List<string>();

        /// <summary>
        /// Create an empty text-builder
        /// </summary>
        public TxtBuilder() { }

        /// <summary>
        /// Create a text-builder preconfigured with a text to build
        /// </summary>
        /// <param name="Text">The text to build. Use "%PropertyName%" to offer placeholders that later values get inserted into.</param>
        public TxtBuilder(string Text)
        {
            Load(Text);
        }

        /// <summary>
        /// Load a new text to build.
        /// </summary>
        /// <param name="Text">The text to build. Use "%PropertyName%" to offer placeholders that later values get inserted into.</param>
        public void Load(string Text)
        {
            if (this.Text == Text)
                return;
            List<string> properties = new List<string>();
            foreach (Match match in Regex.Matches(Text, "%([^\\s%]+)%"))
                properties.Add(match.Groups[1].Value);
            Properties = properties;
            this.Text = Text;
        }

        /// <summary>
        /// Take a message object and build it into a string, ready for logging
        /// </summary>
        /// <param name="Message">The message object to build.</param>
        /// <returns>The finished message, ready for the logfile.</returns>
        public string Convert(PSObject Message)
        {
            string newMessage = Text;
            foreach (string property in Properties)
                if (Message.Properties[property] != null)
                    newMessage = newMessage.Replace($"%{property}%", LanguagePrimitives.ConvertTo<string>(Message.Properties[property].Value));
            return newMessage;
        }
    }
}
