import Alpine from 'alpinejs'
window.Alpine = Alpine
window.csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
window.printImage = function(imageUrl, title) {
  const printWindow = window.open('', '_blank', 'width=800,height=600');
  
  // 检查弹出窗口是否被阻止
  if (!printWindow || printWindow.closed || typeof printWindow.closed == 'undefined') {
      alert('Pop-up window blocked, please allow pop-up window and try again');
      return;
  }
  
  printWindow.document.write(`
    <html>
      <head>
        <title>${title || 'Print Image'}</title>
        <style>
          body { 
            margin: 0; 
            padding: 0; 
            background: white;
            font-family: Arial, sans-serif;
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
          .loading {
            text-align: center;
            padding: 20px;
            color: #666;
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
              print-color-adjust: exact;
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
            .loading {
              display: none;
            }
            * {
              -webkit-print-color-adjust: exact !important;
              print-color-adjust: exact !important;
              color-adjust: exact !important;
            }
          }
        </style>
      </head>
      <body>
        <div class="page">
          <div class="loading">Loading...</div>
          <img id="printImg" src="${imageUrl}" alt="coloring page" style="display: none;" />
        </div>
        <script>
          const img = document.getElementById('printImg');
          const loading = document.querySelector('.loading');
          
          img.onload = function() {
            loading.style.display = 'none';
            img.style.display = 'block';
            
            setTimeout(function() {
              window.print();
              
              setTimeout(function() {
                window.close();
              }, 1000);
            }, 500);
          };
          
          img.onerror = function() {
            loading.innerHTML = 'Loading failed';
            setTimeout(function() {
              window.close();
            }, 2000);
          };
          
          if (img.complete) {
            img.onload();
          }
        </script>
      </body>
    </html>
  `);
  printWindow.document.close();
  
  printWindow.focus();
};

Alpine.start()