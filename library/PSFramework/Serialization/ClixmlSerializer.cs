using System;
using System.IO;
using System.IO.Compression;
using System.Management.Automation;
using System.Text;

namespace PSFramework.Serialization
{
    /// <summary>
    /// Class providing tools to convert to and from clixml, compressed and uncompressed, string and bytes
    /// </summary>
    public static class ClixmlSerializer
    {
        /// <summary>
        /// Converts an object into compressed bytes
        /// </summary>
        /// <param name="Item">The arbitrary object to serialize</param>
        /// <returns>A compressed byte array containing the serialized inputobject</returns>
        public static byte[] ToByteCompressed(object Item)
        {
            byte[] bytes = Encoding.UTF8.GetBytes(PSSerializer.Serialize(Item));
            MemoryStream outputStream = new MemoryStream();
            GZipStream gZipStream = new GZipStream(outputStream, CompressionMode.Compress);
            gZipStream.Write(bytes, 0, bytes.Length);
            gZipStream.Close();
            outputStream.Close();
            return outputStream.ToArray();
        }

        /// <summary>
        /// Converts an object into compressed bytes
        /// </summary>
        /// <param name="Item">The arbitrary object to serialize</param>
        /// <param name="Depth">The depth to which to serialize</param>
        /// <returns>A compressed byte array containing the serialized inputobject</returns>
        public static byte[] ToByteCompressed(object Item, int Depth)
        {
            byte[] bytes = Encoding.UTF8.GetBytes(PSSerializer.Serialize(Item, Depth));
            MemoryStream outputStream = new MemoryStream();
            GZipStream gZipStream = new GZipStream(outputStream, CompressionMode.Compress);
            gZipStream.Write(bytes, 0, bytes.Length);
            gZipStream.Close();
            outputStream.Close();
            return outputStream.ToArray();
        }

        /// <summary>
        /// Converts an object into bytes
        /// </summary>
        /// <param name="Item">The arbitrary object to serialize</param>
        /// <returns>A byte array containing the serialized inputobject</returns>
        public static byte[] ToByte(object Item)
        {
            return Encoding.UTF8.GetBytes(PSSerializer.Serialize(Item));
        }

        /// <summary>
        /// Converts an object into bytes
        /// </summary>
        /// <param name="Item">The arbitrary object to serialize</param>
        /// <param name="Depth">Overrrides the default serialization depth</param>
        /// <returns>A byte array containing the serialized inputobject</returns>
        public static byte[] ToByte(object Item, int Depth)
        {
            return Encoding.UTF8.GetBytes(PSSerializer.Serialize(Item, Depth));
        }


        /// <summary>
        /// Converts an object into compressed string
        /// </summary>
        /// <param name="Item">The arbitrary object to serialize</param>
        /// <returns>A compressed string containing the serialized inputobject</returns>
        public static string ToStringCompressed(object Item)
        {
            return Convert.ToBase64String(ToByteCompressed(Item));
        }

        /// <summary>
        /// Converts an object into compressed string
        /// </summary>
        /// <param name="Item">The arbitrary object to serialize</param>
        /// <param name="Depth">The depth to which to serialize</param>
        /// <returns>A compressed string containing the serialized inputobject</returns>
        public static string ToStringCompressed(object Item, int Depth)
        {
            return Convert.ToBase64String(ToByteCompressed(Item, Depth));
        }

        /// <summary>
        /// Converts an object into string
        /// </summary>
        /// <param name="Item">The arbitrary object to serialize</param>
        /// <returns>A string containing the serialized inputobject</returns>
        public static string ToString(object Item)
        {
            return PSSerializer.Serialize(Item);
        }

        /// <summary>
        /// Converts an object into string
        /// </summary>
        /// <param name="Item">The arbitrary object to serialize</param>
        /// <param name="Depth">Overrrides the default serialization depth</param>
        /// <returns>A string containing the serialized inputobject</returns>
        public static string ToString(object Item, int Depth)
        {
            return PSSerializer.Serialize(Item, Depth);
        }


        /// <summary>
        /// Deserializes an object that was serialized to compressed bytes
        /// </summary>
        /// <param name="Bytes">The compressed bytes to deserialize into an object</param>
        /// <returns>The deserialized object</returns>
        public static object FromByteCompressed(byte[] Bytes)
        {
            MemoryStream inputStream = new MemoryStream(Bytes);
            MemoryStream outputStream = new MemoryStream();
            GZipStream converter = new GZipStream(inputStream, CompressionMode.Decompress);
            converter.CopyTo(outputStream);
            converter.Close();
            inputStream.Close();
            string result = Encoding.UTF8.GetString(outputStream.ToArray());
            outputStream.Close();
            return PSSerializer.Deserialize(result);
        }

        /// <summary>
        /// Deserializes an object that was serialized to compressed string
        /// </summary>
        /// <param name="String">The compressed string to deserialize into an object</param>
        /// <returns>The deserialized object</returns>
        public static object FromStringCompressed(string String)
        {
            return FromByteCompressed(Convert.FromBase64String(String));
        }

        /// <summary>
        /// Deserializes an object that was serialized to bytes
        /// </summary>
        /// <param name="Bytes">The bytes to deserialize into an object</param>
        /// <returns>The deserialized object</returns>
        public static object FromByte(byte[] Bytes)
        {
            return FromString(Encoding.UTF8.GetString(Bytes));
        }

        /// <summary>
        /// Deserializes an object that was serialized to string
        /// </summary>
        /// <param name="String">The string to deserialize into an object</param>
        /// <returns>The deserialized object</returns>
        public static object FromString(string String)
        {
            return PSSerializer.Deserialize(String);
        }
    }
}
