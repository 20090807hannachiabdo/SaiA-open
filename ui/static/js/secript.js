// =======================================================
// SaiA — About page interactions
// =======================================================

document.addEventListener("DOMContentLoaded", () => {
    setCurrentYear();
    setupScrollReveal();
    setupCopyEmail();
});

/** يضع السنة الحالية بالفوتر تلقائياً بدل كتابتها يدوياً كل مرة */
function setCurrentYear() {
    const yearEl = document.getElementById("year");
    if (yearEl) {
        yearEl.textContent = new Date().getFullYear();
    }
}

/** يُظهر الأقسام بتأثير fade/slide لطيف عند الوصول إليها أثناء التمرير */
function setupScrollReveal() {
    const revealEls = document.querySelectorAll(".reveal");
    if (!revealEls.length) return;

    // إن لم يدعم المتصفح IntersectionObserver، أظهر كل شيء فوراً
    if (!("IntersectionObserver" in window)) {
        revealEls.forEach((el) => el.classList.add("is-visible"));
        return;
    }

    const observer = new IntersectionObserver(
        (entries) => {
            entries.forEach((entry) => {
                if (entry.isIntersecting) {
                    entry.target.classList.add("is-visible");
                    observer.unobserve(entry.target);
                }
            });
        },
        { threshold: 0.15 }
    );

    revealEls.forEach((el) => observer.observe(el));
}

/** ينسخ عنوان البريد الإلكتروني للحافظة مع تأكيد بصري بسيط */
function setupCopyEmail() {
    const button = document.getElementById("copy-email-btn");
    const emailLink = document.getElementById("contact-email");
    if (!button || !emailLink) return;

    const email = emailLink.textContent.trim();
    const defaultLabel = button.querySelector(".copy-label")?.textContent || "Copy";

    button.addEventListener("click", async () => {
        try {
            await navigator.clipboard.writeText(email);
            showCopied(button, defaultLabel);
        } catch (err) {
            // بعض المتصفحات القديمة لا تدعم Clipboard API — حل بديل
            fallbackCopy(email);
            showCopied(button, defaultLabel);
        }
    });
}

function showCopied(button, defaultLabel) {
    const label = button.querySelector(".copy-label");
    button.classList.add("copied");
    if (label) label.textContent = "Copied!";

    setTimeout(() => {
        button.classList.remove("copied");
        if (label) label.textContent = defaultLabel;
    }, 1800);
}

function fallbackCopy(text) {
    const tempInput = document.createElement("textarea");
    tempInput.value = text;
    tempInput.style.position = "fixed";
    tempInput.style.opacity = "0";
    document.body.appendChild(tempInput);
    tempInput.focus();
    tempInput.select();
    try {
        document.execCommand("copy");
    } catch (err) {
        // تجاهل بصمت إن فشل الحل البديل أيضاً
    }
    document.body.removeChild(tempInput);
}