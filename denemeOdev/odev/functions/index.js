import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { initializeApp } from 'firebase-admin/app';
initializeApp();

/**
 * Sends a notification to the seller when a new application is created for their supply.
 *
 * Triggered by the creation of a document in the 'supplies/{supplyId}/applications/{applicantId}' path.
 *
 * @param {Object} event - The event object containing parameters and other data.
 * @param {Object} event.params - The parameters of the event.
 * @param {string} event.params.supplyId - The ID of the supply.
 * @param {string} event.params.applicantId - The ID of the applicant.
 * @returns {Promise<null>} - Returns null if any document does not exist or if there is no FCM token.
 */
export var sendNotificationToSeller = onDocumentCreated('supplies/{supplyId}/applications/{applicantId}', async (event) => {

    const supplyId = event.params.supplyId;
    const applicantId = event.params.applicantId;

    console.log('Yeni başvuru oluşturuldu:', supplyId, applicantId);
    

    if (!supplyId) {
        console.error('Geçersiz ürün kimliği:', supplyId);
        return null;
    }

    const supplyDoc = await getFirestore().collection('supplies').doc(supplyId).get();
    if (!supplyDoc.exists) {
        console.error('Ürün bulunamadı:', supplyId);
        return null;
    }

    const sellerId = supplyDoc.get('created_by');
    const productTitle = supplyDoc.get('title');
    console.log("Burası 39. Satır ve aldığım bilgiler şunlar: SellerId: " + sellerId + "ProductTitle: "+ productTitle);

    const applicantDoc = await getFirestore().collection('users').doc(applicantId).get();
    if (!applicantDoc.exists) {
        console.error('Başvuran kullanıcı bulunamadı:', applicantId);
        return null;
    }

    const applicantName = applicantDoc.data().name || 'Bir müşteri';
    console.log("Burası 48. Satır ve aldığım bilgiler şunlar: ApplicantName: " + applicantName);

    const sellerDoc = await getFirestore().collection('users').doc(sellerId).get();
    if (!sellerDoc.exists) {
        console.error('Satıcı bulunamadı:', sellerId);
        return null;
    }

    const sellerToken = sellerDoc.get('fcmToken');
    console.log("Burası 57. Satır ve aldığım bilgiler şunlar: SellerToken: " + sellerToken);
    if (!sellerToken || typeof sellerToken !== 'string' || sellerToken.trim() === '') {
        console.error('Satıcının FCM token\'ı bulunamadı:', sellerId);
        return null;
    }

    const message = {
        notification: {
            title: 'Yeni Başvuru!',
            body: `${applicantName}, ${productTitle} ürününüze başvurdu.`
        },
        token: sellerToken
    };

    console.log('Bildirim gönderiliyor:', message);

    try {
        await getMessaging().send(message);
        console.log('Bildirim başarıyla gönderildi.');
    } catch (error) {
        console.error('Bildirim gönderilirken hata oluştu:', error);
    }
});