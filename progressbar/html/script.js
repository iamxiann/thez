document.addEventListener("DOMContentLoaded", (event) => {
    var ProgressBar = {
        init: function () {
            this.progressLabel = document.getElementById("progress-label");
            this.progressBar = document.getElementById("progress-bar");
            this.progressContainer = document.querySelector(".progress-container");
            this.cancelHint = document.getElementById("cancel-hint");
            this.animationFrameRequest = null;
            this.setupListeners();
        },

        setupListeners: function () {
            window.addEventListener("message", function (event) {
                if (event.data.action === "progress") {
                    ProgressBar.update(event.data);
                } else if (event.data.action === "cancel") {
                    ProgressBar.cancel();
                }
            });
        },

        update: function (data) {
            if (this.animationFrameRequest) {
                cancelAnimationFrame(this.animationFrameRequest);
            }
            clearTimeout(this.cancelledTimer);
            clearTimeout(this.hideTimer);

            this.progressContainer.classList.remove("finishing");
            this.progressLabel.textContent = data.label;
            this.progressBar.style.width = "0%";
            this.cancelHint.style.display = data.canCancel === false ? "none" : "flex";
            this.progressContainer.style.display = "block";
            // restart the entrance animation
            this.progressContainer.classList.remove("showing");
            void this.progressContainer.offsetWidth;
            this.progressContainer.classList.add("showing");

            let startTime = Date.now();
            let duration = parseInt(data.duration, 10);

            const animateProgress = () => {
                let timeElapsed = Date.now() - startTime;
                let progress = timeElapsed / duration;
                if (progress > 1) progress = 1;
                let percentage = Math.round(progress * 100);
                this.progressBar.style.width = percentage + "%";
                if (progress < 1) {
                    this.animationFrameRequest = requestAnimationFrame(animateProgress);
                } else {
                    this.onComplete();
                }
            };
            this.animationFrameRequest = requestAnimationFrame(animateProgress);
        },

        cancel: function () {
            if (this.animationFrameRequest) {
                cancelAnimationFrame(this.animationFrameRequest);
                this.animationFrameRequest = null;
            }
            this.progressLabel.textContent = "Cancelled";
            this.cancelHint.style.display = "none";
            this.progressBar.style.width = "100%";
            this.cancelledTimer = setTimeout(this.onCancel.bind(this), 700);
        },

        onComplete: function () {
            this.playExitAnimation(function () {
                this.postAction("FinishAction");
            }.bind(this));
        },

        onCancel: function () {
            this.playExitAnimation();
        },

        playExitAnimation: function (callback) {
            this.progressContainer.classList.remove("showing");
            this.progressContainer.classList.add("finishing");
            this.hideTimer = setTimeout(() => {
                this.progressContainer.style.display = "none";
                this.progressContainer.classList.remove("finishing");
                this.progressBar.style.width = "0";
                if (callback) callback();
            }, 450);
        },

        postAction: function (action) {
            fetch(`https://progressbar/${action}`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                },
                body: JSON.stringify({}),
            });
        },

        closeUI: function () {
            let mainContainer = document.querySelector(".main-container");
            if (mainContainer) {
                mainContainer.style.display = "none";
            }
        },
    };

    ProgressBar.init();
});
