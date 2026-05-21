import Foundation
import CoreBluetooth
import os

@available(iOS 13.0, *)
extension Peripheral: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            os_log(.info, "Peripheral is in ON state")
            self.setupPeripheralsAndStartAdvertising()
        case .poweredOff:
            os_log(.info, "Peripheral is in OFF state")
        default:
            os_log(.info, "Peripheral is in INVALID state")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        os_log(.info, "Central subscribed to characteristic")
        maxDataBytes = min(central.maximumUpdateValueLength, BLEConstants.MAX_ALLOWED_DATA_LEN)
        verifierDelegate?.onDeviceConnected()
        peripheral.stopAdvertising()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        os_log(.info, "Central unsubscribed from characteristic")
        verifierDelegate?.onDeviceDisconnected()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        os_log(.info, "Received write request for characteristic")
        requests.forEach { request in
            verifierDelegate?.onWrite(uuid: request.characteristic.uuid, data: request.value ?? Data())
            peripheral.respond(to: request, withResult: .success)
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        guard error == nil else {
            os_log(.error, "Failed to add verifier GATT service")
            return
        }
        verifierDelegate?.onPeripheralReady()
        peripheral.startAdvertising([
            CBAdvertisementDataServiceUUIDsKey: [Peripheral.SERVICE_UUID],
            CBAdvertisementDataLocalNameKey: pendingAdvertisementName ?? "verifier"
        ])
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        guard error == nil else {
            os_log(.error, "Failed to start verifier advertisement")
            return
        }
        verifierDelegate?.onAdvertisementStarted()
    }
}
