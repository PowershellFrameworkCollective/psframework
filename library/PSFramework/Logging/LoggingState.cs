namespace PSFramework.Logging
{
    /// <summary>
    /// Used to signal the current processing state of the logging runspace
    /// </summary>
    public enum LoggingState
    {
        /// <summary>
        /// The initial state before the logging runspace is spun up
        /// </summary>
        Unstarted,

        /// <summary>
        /// Spinning up logging providers
        /// </summary>
        Initializing,

        /// <summary>
        /// Ready to process messages
        /// </summary>
        Ready,

        /// <summary>
        /// Currently busy writing messages
        /// </summary>
        Writing,

        /// <summary>
        /// A critical error in the logging runspaces has occured, logging has terminated
        /// </summary>
        Broken,

        /// <summary>
        /// The logging has been fully stopped
        /// </summary>
        Stopped
    }
}
