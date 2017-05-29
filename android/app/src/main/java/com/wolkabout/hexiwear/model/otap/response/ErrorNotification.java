/**
 * Hexiwear application is used to pair with Hexiwear BLE devices
 * and send sensor readings to WolkSense sensor data cloud
 * <p>
 * Copyright (C) 2016 WolkAbout Technology s.r.o.
 * <p>
 * Hexiwear is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * <p>
 * Hexiwear is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * <p>
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

package com.wolkabout.hexiwear.model.otap.response;

import com.wolkabout.hexiwear.util.ByteInputStream;

public class ErrorNotification {

    private final int commandId;
    private final ErrorStatus errorStatus;

    public ErrorNotification(final byte[] bytes) {
        final ByteInputStream inputStream = new ByteInputStream(bytes);
        inputStream.nextBytes(1); // Skip command byte
        commandId = inputStream.nextInt(1);
        errorStatus = ErrorStatus.byValue(inputStream.nextInt(1));
    }

    public int getCommandId() {
        return commandId;
    }

    public ErrorStatus getErrorStatus() {
        return errorStatus;
    }

    @Override
    public String toString() {
        return "ErrorNotification{" +
                "commandId=" + commandId +
                ", errorStatus=" + errorStatus +
                '}';
    }

    public enum ErrorStatus {
        SUCCESS(0), /*!< The operation was successful. */
        IMAGE_DATA_NOT_EXPECTED(1), /*!< The OTAP Server tried to send an image data chunk to the OTAP Client but the Client was not expecting it. */
        UNEXPECTED_TRANSFER_METHOD(2), /*!< The OTAP Server tried to send an image data chunk using a transfer method the OTAP Client does not support/expect. */
        UNEXPECTED_COMMAND_ON_DATA_CHANNEL(3), /*!< The OTAP Server tried to send an unexpected command (different from a data chunk), on a data Channel (ATT or CoC), */
        UNEXPECTED_L2CAP_OR_PSM(4), /*!< The selected channel or PSM is not valid for the selected transfer method (ATT or CoC),. */
        UNEXPECTED_OTAP_PEER(5), /*!< A command was received from an unexpected OTAP Server or Client device. */
        UNEXPECTED_COMMAND(6), /*!< The command sent from the OTAP peer device is not expected in the current state. */
        UNKNOWN_COMMAND(7), /*!< The command sent from the OTAP peer device is not known. */
        INVALID_COMMAND_LENGTH(8), /*!< Invalid command length. */
        INVALID_COMMAND_PARAMETER(9), /*!< A parameter of the command was not valid. */
        FAILED_IMAGE_INTEGRITY_CHECK(10), /*!< The image integrity check has failed. */
        UNEXPECTED_SEQUENCE_NUMBER(11), /*!< A chunk with an unexpected sequence number has been received. */
        IMAGE_SIZE_TOO_LARGE(12), /*!< The upgrade image size is too large for the OTAP Client. */
        UNEXPECTED_DATA_LENGTH(13), /*!< The length of a Data Chunk was not expected. */
        UNKNOWN_FILE_IDENTIFIER(14), /*!< The image file identifier is not recognized. */
        UNKNOWN_HEADER_VERSION(15), /*!< The image file header version is not recognized. */
        UNEXPECTED_HEADER_LENGTH(0x16), /*!< The image file header length is not expected for the current header version. */
        UNEXPECTED_HEADER_FIELD_CONTROL(0x17), /*!< The image file header field control is not expected for the current header version. */
        UNKNOWN_COMPANY_ID(0x18), /*!< The image file header company identifier is not recognized. */
        UNEXPECTED_IMAGE_ID(0x19), /*!< The image file header image identifier is not as expected. */
        UNEXPECTED_IMAGE_VERSION(20), /*!< The image file header image version is not as expected. */
        UNEXPECTED_IMAGE_FILE_SIZE(21), /*!< The image file header image file size is not as expected. */
        INVALID_SUB_ELEMENT_LENGTH(22), /*!< One of the sub-elements has an invalid length. */
        IMAGE_STORAGE_ERROR(23), /*!< An image storage error has occurred. */
        INVALID_IMAGE_CRC(24), /*!< The computed CRC does not match the received CRC. */
        INVALID_IMAGE_FILE_SIZE(25), /*!< The image file size is not valid. */
        INVALID_L2CAP_PSM(26), /*!< A block transfer request has been made via the L2CAP CoC method but the specified Psm is not known. */
        NO_L2CAP_PSM_CONNECTION(27), /*!< A block transfer request has been made via the L2CAP CoC method but there is no valid PSM connection. */
        NUMBER_OF_STATUSES(28);

        private final int value;

        ErrorStatus(final int value) {
            this.value = (byte) value;
        }

        public static ErrorStatus byValue(final int value) {
            for (ErrorStatus errorStatus : values()) {
                if (errorStatus.value == value) {
                    return errorStatus;
                }
            }
            return null;
        }
    }

}
