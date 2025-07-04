import Alpine from 'alpinejs';
window.Alpine = Alpine;
window.csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");

window.printImage = function(imageUrl, title) {
  const printWindow = window.open('', '_blank', 'width=800,height=600');

  // Check if the pop-up was blocked
  if (!printWindow || printWindow.closed || typeof printWindow.closed == 'undefined') {
    alert('Pop-up window blocked, please allow pop-up window and try again');
    return;
  }

  // Define the styles directly as a string to be added to the head
  const styles = `
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
  `;

  // Set the title of the new window
  printWindow.document.title = title || 'Print Image';

  // Create and append the style element
  const styleElement = printWindow.document.createElement('style');
  styleElement.textContent = styles;
  printWindow.document.head.appendChild(styleElement);

  // Create the body content
  const bodyContent = `
    <div class="page">
      <div class="loading">Loading...</div>
      <img id="printImg" src="${imageUrl}" alt="coloring page" style="display: none;" />
    </div>
  `;

  // Set the innerHTML of the body
  printWindow.document.body.innerHTML = bodyContent;

  // Add the script to the body for image handling
  const scriptElement = printWindow.document.createElement('script');
  scriptElement.textContent = `
    const img = document.getElementById('printImg');
    const loading = document.querySelector('.loading');

    img.onload = function() {
      loading.style.display = 'none';
      img.style.display = 'block';

      // Give browser a moment to render before printing
      setTimeout(function() {
        window.print();

        // Close window after printing (with a small delay)
        setTimeout(function() {
          window.close();
        }, 1000);
      }, 500);
    };

    img.onerror = function() {
      loading.innerHTML = 'Loading failed';
      // Close window if image fails to load
      setTimeout(function() {
        window.close();
      }, 2000);
    };

    // If image is already in cache, onload might not fire, so check img.complete
    if (img.complete) {
      img.onload();
    }
  `;
  printWindow.document.body.appendChild(scriptElement);

  // It's good practice to call close() even when using DOM manipulation,
  // but it's less critical than with document.write().
  // printWindow.document.close(); // Not strictly necessary here as content is complete

  printWindow.focus();
};

Alpine.start();
// import Alpine from 'alpinejs';
// window.Alpine = Alpine;
// window.csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
// window.printImage = function(imageUrl, title) {
//   const printWindow = window.open('', '_blank', 'width=800,height=600');
  
//   if (!printWindow || printWindow.closed || typeof printWindow.closed == 'undefined') {
//       alert('Pop-up window blocked, please allow pop-up window and try again');
//       return;
//   }
  
//   printWindow.document.write(`
//     <html>
//       <head>
//         <title>${title || 'Print Image'}</title>
//         <style>
//           body { 
//             margin: 0; 
//             padding: 0; 
//             background: white;
//             font-family: Arial, sans-serif;
//           }
//           .page {
//             width: 210mm;  /* A4 width */
//             height: 297mm; /* A4 height */
//             margin: 0 auto;
//             display: flex;
//             justify-content: center;
//             align-items: center;
//             padding: 10mm;
//             box-sizing: border-box;
//           }
//           img { 
//             max-width: 100%;
//             max-height: 100%;
//             object-fit: contain;
//             display: block;
//           }
//           .loading {
//             text-align: center;
//             padding: 20px;
//             color: #666;
//           }
//           @media print {
//             @page {
//               margin: 0;
//               size: A4;
//             }
//             body { 
//               margin: 0; 
//               padding: 0; 
//               -webkit-print-color-adjust: exact;
//               print-color-adjust: exact;
//             }
//             .page {
//               width: 100%;
//               height: 100vh;
//               margin: 0;
//               padding: 8mm;
//             }
//             img { 
//               max-width: 100%;
//               max-height: 100%;
//               object-fit: contain;
//             }
//             .loading {
//               display: none;
//             }
//             * {
//               -webkit-print-color-adjust: exact !important;
//               print-color-adjust: exact !important;
//               color-adjust: exact !important;
//             }
//           }
//         </style>
//       </head>
//       <body>
//         <div class="page">
//           <div class="loading">Loading...</div>
//           <img id="printImg" src="${imageUrl}" alt="coloring page" style="display: none;" />
//         </div>
//         <script>
//           const img = document.getElementById('printImg');
//           const loading = document.querySelector('.loading');
          
//           img.onload = function() {
//             loading.style.display = 'none';
//             img.style.display = 'block';
            
//             setTimeout(function() {
//               window.print();
              
//               setTimeout(function() {
//                 window.close();
//               }, 1000);
//             }, 500);
//           };
          
//           img.onerror = function() {
//             loading.innerHTML = 'Loading failed';
//             setTimeout(function() {
//               window.close();
//             }, 2000);
//           };
          
//           if (img.complete) {
//             img.onload();
//           }
//         </script>
//       </body>
//     </html>
//   `);
//   printWindow.document.close();
  
//   printWindow.focus();
// };

// Alpine.start();