import Alpine from 'alpinejs'
window.Alpine = Alpine
window.csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

window.printImage = function(imageUrl, title) {
    const printWindow = window.open('', '_blank');
    printWindow.document.write(`
      <html>
        <head>
          <style>
            body { 
              margin: 0; 
              padding: 0; 
              background: white;
            }
            .page {
              width: 210mm;  /* A4 width */
              height: 297mm; /* A4 height */
              margin: 0 auto;
              display: flex;
              justify-content: center;
              align-items: center;
              padding: 10mm;
              box-sizing: border-box;
            }
            img { 
              max-width: 100%;
              max-height: 100%;
              object-fit: contain;
              display: block;
            }
            @media print {
              @page {
                margin: 0;
                size: A4;
              }
              body { 
                margin: 0; 
                padding: 0; 
                -webkit-print-color-adjust: exact;
              }
              .page {
                width: 100%;
                height: 100vh;
                margin: 0;
                padding: 8mm;
              }
              img { 
                max-width: 100%;
                max-height: 100%;
                object-fit: contain;
              }
              /* 隐藏浏览器默认的页眉页脚 */
              * {
                -webkit-print-color-adjust: exact !important;
                color-adjust: exact !important;
              }
            }
          </style>
        </head>
        <body>
          <div class="page">
            <img src="${imageUrl}" alt="coloring page" onload="window.print(); window.close();" />
          </div>
        </body>
      </html>
    `);
    printWindow.document.close();
}

Alpine.start()