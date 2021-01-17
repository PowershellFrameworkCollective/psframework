using System;

namespace PSFramework.Utility
{
    /// <summary>
    /// Simple wrapper around Exception to integrate the PSFramework localization feature.
    /// </summary>
    [Serializable]
    public class PsfException : Exception
    {
        /// <summary>
        /// The full string representing the message
        /// </summary>
        public string String;

        /// <summary>
        /// Any values to format into the message string
        /// </summary>
        public object[] StringValues = new object[0];

        /// <summary>
        /// The script callstack at the time this exception was generated.
        /// </summary>
        public Message.CallStack CallStack = UtilityHost.FriendlyCallstack;

        /// <summary>
        /// The localized message to show
        /// </summary>
        public override string Message
        {
            get
            {
                string message = "";
                if (StringValues.Length == 0)
                    message = Localization.LocalizationHost.Read(String);
                else
                    message = Localization.LocalizationHost.Read(String, StringValues);
                if (InnerException != null)
                    message = String.Join(" | ", message, InnerException.Message);
                return message;
            }
        }

        /// <summary>
        /// Create an empty eception
        /// </summary>
        public PsfException()
        {

        }
        /// <summary>
        /// Create a simple exception including a message string
        /// </summary>
        /// <param name="String">The string representing the message</param>
        public PsfException(string String)
        {
            this.String = String;
        }
        /// <summary>
        /// Create a full exception object with all metadata
        /// </summary>
        /// <param name="String">The string representing the message</param>
        /// <param name="InnerException">An inner exception to pass through</param>
        /// <param name="StringValues">Any values to format into the message</param>
        public PsfException(string String, Exception InnerException, params object[] StringValues)
            :base(String, InnerException)
        {
            this.String = String;
            if (StringValues != null)
                this.StringValues = StringValues;
        }
    }
}
