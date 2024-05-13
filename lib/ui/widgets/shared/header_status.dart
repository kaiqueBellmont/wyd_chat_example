import 'package:flutter/material.dart';
import 'package:labalaba/ui/widgets/home/profile_image.dart';

class HeaderStatus extends StatelessWidget {
  final String? username;
  final String? imageUrl;
  final bool online;
  final String? description;
  final String? typing;
  const HeaderStatus(this.username, this.imageUrl, this.online, {this.description, this.typing});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      child: Row(
        children: [
          ProfileImage(
            imageUrl: imageUrl!,
            online: online,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Text(
                  username!.trim(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: typing == null
                    ? Text(
                        online ? 'Online' : description!,
                        style: Theme.of(context).textTheme.caption,
                      )
                    : Text(
                        typing!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontStyle: FontStyle.italic),
                      ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

//test with mutiple devices
// see you in the next video!!
